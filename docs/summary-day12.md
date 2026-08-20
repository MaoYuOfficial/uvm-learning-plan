# 第 12 天总结：整理 GitHub + README（2026-08-20）

## 今日目标
把仓库整理到"别人 clone 按 README 能跑通仿真"：写 README（波特率/帧格式/状态机/如何跑仿真），按"读者 3 分钟能复现"标准改。完成标志：fresh clone 实测两个仿真跑通。

## 我做了什么
- **README 从 406 字节骨架扩到完整版**（目录结构 / FSM 状态机 / UART TX-RX 两节），草稿迭代 5 轮，按"3 分钟复现"标准审：
  - GUI 步骤修正：Simulate 选**模块名**不带 .v；第一步先 **File → Change Directory** 到仓库根目录（否则 work 库建错位置，Simulate 找不到设计）
  - 期望输出用代码块包起来，写清"通过标准"——跑完看到什么算成功、怎么判对错
- **fresh clone 实测**（把仓库 clone 到全新目录从零跑）——完成标志验证：
  - FSM：vlog fsm1.v + tb_fsm1.v → vsim → `$finish @ 70ns`，out 在 25/35/55/65ns 各翻转一次，与 README 期望输出完全一致
  - UART：7 个文件编译 Errors 0 → vsim → 3 行 PASS + 总结 `PASS 3, FAIL 0`
- **顺手修掉两个"别人 clone 必挂"的 bug**（平时都被 work 库缓存掩盖，fresh 编译才暴露）：
  - `tb_uart_top.v` 的 `send_byte` task 缺 `begin...end`——ModelSim 要求多语句 task 体必须包 begin/end
  - 编译清单漏 `uart_baud.v`——`uart_tx.v` 例化了它；vlog 编译单个文件不检查例化是否存在，vsim 优化时才发现 `Module 'uart_baud' is not defined`
- 打卡 `ca46321`（README + 两个修复）已 push 到 GitHub

## 我学到的
- **"3 分钟复现"标准的做法**：写期望输出（跑完看到什么算成功）+ 通过标准（怎么判对错），而不是只写"怎么点"
- **.v 不是脚本**：`.v` 是硬件描述代码（被 vlog 编译成 work 库里的东西），脚本是 `.do`/`.bat`（指挥 ModelSim 怎么跑）。读者分不清"编译 .v"和"执行脚本"两个动作就跑不起来
- **GUI 操作 = 命令的文字翻译**：vlog=Compile、vsim=Simulate、run -all=Run-All，一一对应；不会写脚本也能写命令，因为命令就是平时 GUI 点的那几步
- **参数以代码为准**：写 README 前先查模块参数（`UART_BPS = 115200`），记忆会骗人

## 今天我踩的坑（都改过来了）
- **`tb_uart_top` 缺 begin/end**：task 多语句体必须用 begin...end 包住；之前一直 work 库缓存兜底，fresh compile 才暴露（命令行 vsim 会加载旧编译结果，掩盖语法错误）
- **编译清单漏 `uart_baud.v`**：vlog 单文件编译不查例化，vsim 优化时才报 `Module not defined`——编译清单要按例化层级把依赖文件列全
- **Simulate 对话框列的是模块名不是文件名**（`tb_uart_top` 不是 `tb_uart_top.v`）；ModelSim 要先 cd 到仓库根目录再编译
- **期望输出顶格写在列表里** → 用代码块（三个反引号）包起来才清晰、可复制
