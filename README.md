# uvm-learning-plan

数字IC验证学习计划。

## 目录结构

| 目录 | 用途 |
| --- | --- |
| rtl/ | RTL 设计（UART TX/RX） |
| tb/ | 测试平台（SV TB → UVM 环境） |
| sim/ | 仿真脚本 + 简单仿真文件 |
| docs/ | 笔记、波形截图、博客素材 |

## 仿真工具

- 主力：ModelSim SE-64 10.4（本地）
- 备用：EDA Playground

## FSM状态机

- 包含的主要代码：**rtl/**文件夹下，fsm_skeleton.v（三段式状态机骨架模版）/fsm1.v（我自己写的fsm状态机）;**tb/**文件夹下，tb_fsm1.v（我写的状态机测试台）。

- 时钟：周期10ns（每#5翻转一次，上升沿在t=5,15,25...）
- 状态：Sa = 0 / Sb = 1

- 输入：clk（时钟）/areset（复位）/in（输入数据）
- 输出：out（输出状态）

- 主要功能：类似一个小开关，in为0时就一直翻转状态，为1时就保持当前状态，按areset默认回到Sb状态

- 仿真方式：1.ModelSim 打开后，File → Change Directory找到仓库根目录，Compile → Compile：在rtl/目录下选fsm1.v 在tb/目录下选tb_fsm1.v
2.Simulate → Simulate Design：选 tb_fsm1
3.命令行敲 run -all

- 结果日志：复位（areset拉高后out立即为1）/翻转（in=0时out持续翻转）/保持（in=1时状态不变）/时序（输出只在上升沿变化）

-期望输出：Log末尾为
```
Errors: 0, Warnings: 0, $finish @ 70ns。
```
同时核对日志out在25/35/55/65ns各翻转一次，40~50ns间in=1时不变。

## UART TX/RX

- 包含的主要代码：**rtl/**文件夹下，rst_sync.v（复位同步器，用于同步复位信号的释放和异步复位）/ uart_baud.v（波特率发生器）/ uart_rx.v（数据接收器）/uart_loop.v（环回模块）/uart_tx.v（数据发送器）/uart_top.v（顶层模块，例化并连接各子模块）。**tb/**文件夹下，tb_uart_top.v（整个UART的测试台）

- 时钟：周期20ns，频率50MHz（每#10翻转一次）
- 波特率：115200
- 帧格式：1起始位+8数据位+1停止位，无校验位

- 输入：clk（时钟） / rst_n（复位）/ rxd（数据输入）
- 输出：txd（数据输出）

- 主要功能：UART协议TX/RX串口，用于数据的收发

- 仿真方式：1.ModelSim 打开后，File → Change Directory找到仓库根目录，Compile → Compile：在rtl/目录下选 uart_baud.v  rst_sync.v  uart_rx.v  uart_tx.v  uart_loop.v  uart_top.v  在tb/目录下选 tb_uart_top.v
2.Simulate → Simulate Design：选tb_uart_top
3.命令行敲 run -all

- 结果日志：PASS（输入与输出匹配，通过次数）/ FAIL（输入与输出不匹配，失败次数）/ exp（期望输出）/ got （实际输出）

- 期望输出：
```
PASS: exp 0x55 == got 0x55
PASS: exp 0xaa == got 0xaa
PASS: exp 0x3c == got 0x3c
--- 总结：共 3 帧，PASS 3, FAIL 0 ---
```