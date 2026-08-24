# 第 15 天总结：TB 类化第一步——声明升级 + 认识 SV 容器（2026-08-23）

## 今日目标（按新学习方法：改造驱动，用到才学）
第 15 天从"SV 数据类型大全"重规划为"TB 改造第一步"：把 4 个 UART TB 的 reg/wire 全改 logic/bit，改名 .sv，仿真行为不变；认识 SV 的容器（四类数组/struct/enum），为明天 uart_transaction 类铺路。学习方式改为**改造驱动**：先做任务，卡住才查资料，知识点碎片化嵌入。

## 我做了什么
- **任务 A：TB 声明全面升级 logic**：4 个 UART TB（top/tx/rx/baud）reg/wire → logic，文件改名 .sv，重编译 Errors 0，主 TB 仿真 3/3 PASS（0x55/0xAA/0x3C）行为与改前一字不差；rx 采样序列、baud 计数也一致
- **任务 B：认识 SV 容器**（data_types.sv 六例跑通）：
  1. 定宽数组：3 帧期望值缓存（exp_arr），for + $size 遍历
  2. 动态数组：波特率分频表（baud_div），new[3] 分配再逐个填值
  3. 队列：模拟收 3 字节待处理（rx_q），push_back 入队、while + pop_front 先进先出出队
  4. 关联数组：按名字查分频（baud_table），exists 查在不在、first/next 遍历
  5. struct：一帧打包（uart_frame_t，data + parity_err），点号取字段
  6. enum：TX 状态名（IDLE/START/DATA/STOP），name() 转文字打印

## 我学到的（每条都对应明天/后天的用途）
- **logic vs reg vs wire**：类型跟驱动方式走（reg=过程赋值、wire=连续赋值）；SV 里 logic 一统（4 态、两种驱动都行、但只许一个驱动源）；bit 是 2 态，接 DUT 的信号必须 logic（X 会被静默转 0 藏 bug）
- **四类容器**：定宽=固定坐席（编译期定死）、动态=运行时 new 定大小、队列=两头进出先进先出、关联=按名字查（键值对）
- **struct** = 把一帧打包成一个变量（点号取字段）；**明天 uart_transaction 类就是它的升级版**（class = struct + 方法）
- **enum** = 给状态/类型起名字（可读、编译器防手滑、波形显示名字）；明天 transaction 的帧类型用它
- **typedef 格式**：`typedef 类型 名字;`——类型内容在前（struct{...}/enum{...}）、名字放最后、分号结尾；起完名和 int/logic 平级
- **点号三种用法**：进模块拿信号（utop.rx_data）、取 struct 字段（frame.data）、调方法（q.push_back()）——都是"的"
- **声明必须在语句前**：begin 块里所有变量声明集中到开头，第一个语句之后不能再声明；typedef 放模块级
- **仿真日志用英文**：ModelSim 10.4 输出 $display 中文会乱码（编码坑），日志英文、中文只留注释

## 今天我踩的坑（都改过来了）
1. **for 条件用元素值当条件**（三版才改对）：`for(i=0; exp_arr[i]; i++)` 会在 i=3 越界读，且存 0x00 时循环一次都不跑——条件必须是 `i < $size(exp_arr)`
2. **int 不能再加位宽**：`int [2:0]` 非法（int 自带 32 位），`logic [2:0]` 才合法
3. **new 只分配不填值**：`new[3]` 腾格子，数据要 `baud_div[0]=...` 自己填
4. **for 三段式**：`for(初始; 条件; 步进)` 只有三个槽，条件和步进不能换位
5. **声明在语句后**：SV 不允许，所有声明挤到 initial 开头（报 Illegal declaration after statement）
6. **`0x55` 字面量 ModelSim 不认**：vlog 10.4 只认 `8'h55` 格式（位宽'进制 值），C 风格 0x 前缀报 near "x55"
7. **$display 中文乱码**：ModelSim 10.4 对中文输出有编码坑，日志统一英文
8. **typedef 位置**：类型定义放模块级，变量声明放 initial 开头

## 明天的引子
uart_transaction 类 = 今天的 struct 升级版（打包数据 + 自带方法 display/compare）；generator → 队列 → driver 通信 = 今天练的队列上场。学习方法已写入计划文档（改造驱动、用到才学、卡住再查）。

## 打卡
- day15: 4 个 UART TB 转 .sv + logic（行为不变）+ sv-practice/data_types.sv 六例跑通 + 学习方法重规划（计划文档双副本同步）
