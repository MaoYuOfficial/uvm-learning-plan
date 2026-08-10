# Day 4 总结（2026-08-10）

## 学了什么
- 语法篇 12-16 讲（在线版）：语法简介（wire/reg 法律）/ 程序框架（initial 只跑一次、不可综合；reg≠寄存器）/ 高级知识点（阻塞 vs 非阻塞、parameter、generate）/ 状态机 FSM
- **阻塞 vs 非阻塞**：`=` 立即生效、`<=` 先快照后统一更新（右值全是旧值）；时序逻辑用 `<=`、组合逻辑用 `=`
- **防锁存器三招**：if 配 else、case 配 default、组合逻辑所有路径都赋值（先赋默认值再覆盖）
- **casez 的 `?` 通配符**：8 位优先编码器 256 个分支 → 9 行；优先级靠行序（第一个匹配生效）
- **FSM 三段式**：时序段（`state <= next_state` + 复位）/ 组合段（`next_state = state` 打底 + case）/ 输出段（Moore 查 state）
- 复位不是自动的：RTL 是响应者不是发起者，复位由 POR/外部电路驱动，仿真里要手动模拟

## 踩的坑
- HDLBits always_if：else 必须与 end 平级；最外层 if 必须配 else（否则锁存器）
- `output` 端口在 always 里赋值必须声明 `output reg`
- ModelSim：vsim 默认优化 → 必须 `-novopt` 才有波形；编译要连设计文件一起编（Module 'xxx' is not defined）
- `output` 默认是 wire，不能过程赋值（vlog-2110 Illegal reference to net）

## 成果
- HDLBits Procedures 8 题全绿（alwaysblock 系列 / always_if 系列 / always_case 系列 / always_nolatch）
- fsm1 三段式状态机本地 ModelSim 仿真通过：异步复位到 B / in=0 翻转 / in=1 保持 / out 只在时钟沿变化，全部波形验证
- rtl/fsm1.v + tb/tb_fsm1.v + rtl/fsm_skeleton.v（标准骨架模板）

## 我默写的 FSM 骨架（完成标志·伪代码版）
```
//声明输入输出
module test(
input in,
input res,
input clk,
output out)  // 至少包括输入输出，时钟和复位

//声明状态变量
localparam 复位变量，状态变量
设置中间变量表示状态

//时序
always时序逻辑，如果是异步复位需要加or
触发复位时状态<=默认值；
触发clk时状态<=下一个状态；

//状态变化
always@(*)组合逻辑
先状态复位防止锁存器
case语句表达状态变化

//输出
按照要求表达好对应输出就行
简单组合逻辑可以assign
复杂的或者时序逻辑输出用always
```
结构五要素全对（localparam/中间变量/时序段/组合段防锁存器/输出），待补：localparam 真值、reg 声明、敏感列表完整写法、default、复位值。对照标准骨架见 rtl/fsm_skeleton.v。

## 感悟
- 阻塞/非阻塞：第一次把 `c <= b` 答成 c=a，看快照波形图后才真正懂——**c 拿的是旧 b，输出晚一拍**。图比文字管用。
- **代码是响应者不是发起者**：以为 always 会"自动触发"复位，追问一串才发现复位要靠 POR/外部电路驱动，RTL 只是监听输入。硬件里信号不会自己冒出来。
- **硬件里的 for 是编译期展开**：不是运行时循环，只是少打字的复制粘贴。
- **casez 的 ? 让我明白查表的本质**：关心哪一位就写哪一位，优先级靠行序。
- **锁存器是摔出来的**：always_if 没写 else 摔了一跤，always_if2 亲手修好——"每个分支都赋值"从此进肌肉记忆。
- ModelSim 第一坑是 -novopt，第二坑是编译漏文件——**报错先看是不是"没编译/没存盘"**。
- default 是"查无此项"的收容所：防锁存器 + 兜底非法状态 + 接住仿真 x。

## 明日（Day 5）待办
- [ ] HDLBits fsm2/fsm3 补 1-2 题（状态机手感第 6 天 UART 会继续练）
- [ ] 明早复习：对照 rtl/fsm_skeleton.v 再默写一遍骨架
- [ ] 正式进入 UART：波特率发生器
