# 第 9 天总结：UART 顶层环回 + uart_loop 协调模块（2026-08-16）

## 今日目标
写 `uart_top.v`（TX+RX 环回）+ initial 块 TB；完成标志：环回仿真打印出收到的字节。

## 我做了什么
- **给 uart_tx.v 加 tx_busy**：第一次声明成 `output tx_busy` 却在 always 里赋值，编译报 syntax error（output reg 老坑第 4 次）。最后选方案 2：`assign tx_busy = (state != IDEL);`，case 里删掉 busy 赋值。
- **自己写 uart_loop.v，多版迭代**：端口 → 打拍上升沿检测 → 三态机 IDLE/SEND/WAIT_TX → 快照 flash_data → 输出 tx_req/tx_data。排掉的雷：IDEL/IDLE 拼写不一致、wire rx_start_flag 声明了 assign 却写 start_flag、tx_reg 未声明、flash_data 两个 always 块多驱动、输出块 else 里写 state 多驱动、`tx_data <= flash_data` 放错沿（读旧值）、复位没清 flash_data/tx_req/tx_data。
- **自己写 uart_top.v**：命名端口连接例化三个模块，对外只有 clk/rst_n/rxd/txd。第一版有 `.reg txd (txd)` 语法错和 uart_loop 实例缺分号，两处改掉后整套 RTL 编译 Errors 0。
- **自己写 tb_uart_top.v**：无端口 TB；clk/rst_n/rxd 初始化；0x55 激励（10 位 × 8680ns）；`$monitor` 全程留痕 + `$display("收到字节: 0x%02x")` 打印完成标志。
- **仿真通过**：Log 铁证收到 0x55；txd 从 104.27µs 起回发一模一样的 0x55 帧，182.39µs 停止位结束；Errors 0。
- **波形核对**：ModelSim GUI 截图（放大到 85~110µs 握手区，游标 85/110µs），裁剪成交付图 docs/day9-uart-loop-waveform.png；配合 docs/day9-uart-loop-design.png（接口框图 + 状态机图）。

## 我学到的
- **reg 不是"寄存器"的意思**：它是"过程赋值变量"的意思。always 块里赋值的目标必须 reg；assign 的目标必须是 wire。txd 用 case 多分支所以必须 output reg，tx_busy 只是一个比较表达式所以用 assign 更干净。
- **`state != IDEL` 为什么能算 busy**：状态编码里唯一不忙的状态就是 IDLE，所以"不等于 IDEL"精确等于"在发帧"。这种写法隐含约定：以后加新状态要先想清楚它忙不忙。
- **loop 为什么要打拍检测 rx_done 上升沿**：done 的脉冲宽度是实现细节，不是接口契约（正点原子版的 recv_done 会持续整个停止位时间）。打拍边沿检测让 loop 对宽度免疫；同时钟域，这里打拍不是为了防亚稳态（那是 rxd 异步输入才需要考虑的）。
- **为什么还要 done 接口**：uart_rx 里的打拍检测的是 rxd 下降沿（帧头 start_flag），done 是帧尾"数据有效"事件，两个事件差一整帧。帧时序是 RX 的内部知识，数据一有效靠 done 通知外部，loop 不自己数位。
- **两种接口风格二选一**：A) rx 出电平、loop 打拍检测上升沿（正点原子风格）；B) rx 出 1 拍脉冲、loop 直接 if(rx_done)。我现在的 uart_rx 恰好是 B，但 loop 按 A 写，对宽度免疫。
- **同一沿非阻塞赋值读旧值**：`flash_data <= rx_data` 和 `tx_data <= flash_data` 写在同一沿，tx_data 拿到的是进入这一拍之前的旧 flash_data。输出要放到 state==SEND 分支，那时 flash_data 已是新值。
- **一个 reg 不能出现在两个 always 块**：多驱动非法，结果不确定。state 兜底 else 写错块也是同一类问题。
- **$finish vs $stop**：$finish 结束整个仿真进程（跑完自动收工用）；$stop 暂停挂起等你 continue（调试看波形用）。
- **$display vs $monitor**：$display 执行到才打一行（关键事件）；$monitor 信号一变自动打（全程留痕），但整个仿真同时只有一个 monitor 生效。
- **完成标志必须数据级比对**：直接比 rxd/txd 电平会被 0x55 的自相似波形骗过，而且两帧时间错开一整帧。硬标准是 TX 发的字节 == RX 收的字节。
- **`0x%02x` 格式**：%x 十六进制、02 补零到 2 位，8 位数据正好两个十六进制位。
- **例化端口连接只写端口名**：`.txd(txd)`，不带 reg。

## 我问的问题
1. tx_busy 为什么能这样写？→ always 里赋值必须 reg；assign 左边必须是 wire
2. 我是说这个计算方式（state != IDEL）？→ 非 IDEL 全算忙，因为唯一不忙的状态是 IDLE
3. 有 rx_done 代表接收完成，为什么还要打拍？→ done 的宽度是实现细节；上升沿才是"新一帧"事件
4. 都写了打拍检测接收状态，干嘛还要 done 接口？→ start_flag 是帧头、done 是帧尾，差一整帧
5. 我是说 loop 里面加打拍寄存器？→ 接口风格二选一：电平+边沿检测 vs 1 拍脉冲直用
6. loop 加了打拍，recv_done 还有啥用？→ 打拍的输入就是它，没有 done 打拍没东西可打
7. $display 和 $monitor 有啥区别？→ 执行打印 vs 信号变自动打；同时只一个 monitor 生效
8. 完成标志不是 rxd 和 txd 一样就行了吗？→ 电平相似会被 0x55 骗；时间错开一帧；要数据级比对
9. 收到字节 0x%02x 这个看不懂？→ %x 十六进制，02 补零到两位

## 今天我答错/踩的坑（都改过来了）
- `output tx_busy` 却在 always 里赋值 → output reg 老坑第 4 次，最终用 assign 方案
- IDEL/IDLE 拼写不一致 → Undefined variable
- `wire rx_start_flag` 声明了，`assign start_flag` 名字对不上
- `tx_reg` 未声明 → 应为 tx_req
- flash_data 被两个 always 块赋值 → 多驱动，职责合并到一个块
- 输出块 else 里写 `state <= IDEL` → state 多驱动，删掉
- `tx_data <= flash_data` 放在 IDLE→SEND 沿 → 非阻塞读旧值，改放 state==SEND 输出
- 复位只清 state 没清 flash_data/tx_req/tx_data → 补齐
- TB 写了 input/output 端口 → TB 无端口，内部 reg 驱动 / wire 观察
- TB clk 没初始化、rst_n 从 X 直接拉高、rxd 没先置空闲高 → 全补
- `$monitor($time " ...")` 缺逗号 + $time 进参数会每时刻刷屏 → $time 放格式串用 %t
- uart_top 第一版：`.reg txd (txd)` 语法错、实例缺分号
