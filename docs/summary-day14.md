# 第 14 天总结：Python 首练 + 两周复盘（2026-08-22）

## 今日目标
用 Python 写脚本解析第 7 天仿真 Log（提取 PASS/FAIL、统计通过率、输出一行摘要，以后仿真结果统计复用）；复盘第 1-2 周。💬 复述任务本次跳过。完成标志：Python 脚本能正确统计 Log。

## 我做了什么
- **Python 从零基础开始，四课学完就上阵**：
  1. 变量 + `print`：脚本 = 从上往下执行的指令清单；变量 = 存数据的盒子；`print` = 显示（对应对照 Verilog 的 initial 块 / reg / $display）
  2. `for` + `if`：`for 名字 in 一串东西` 逐个拿出来；`in` 判断字符串包含；**缩进 = begin/end**（Python 最大特点）
  3. `open` 读文件：`for line in f:` 逐行读；`..` 上一级相对路径；`rstrip()` 剥行尾换行符
  4. `split()` 切字符串 + 索引取段：从 `# Errors: 0, Warnings: 1` 里提取数字
- **写出 parse_logs.py 并三种日志验证全过**：
  - 第 7 天日志（$monitor 转储，无 PASS/FAIL）→ `PASS = 0 FAIL = 0 通过率=没有检查行，不计算通过率 Errors = 0 Warnings = 1`
  - 第 10 天自动比对 TB 真实日志 → `PASS = 3 FAIL = 0 通过率 = 1.0`
  - 自己构造的含 FAIL 测试日志 → `PASS = 2 FAIL = 1 通过率 = 0.6666...`（手算核对一致）
- **复盘第 1-2 周**：day1-13 全景（数电基础 → Verilog 语法 → UART 全链路 → 自动比对 TB → 复位同步器 → README），并讨论"环回的结构位置 vs 开发顺序 vs 数据传输顺序"

## 我学到的
- **Python 最小可用知识**：变量、print、for/if、open 读文件、split/rstrip、`#` 注释；缩进决定代码块归属
- **相对路径从"终端当前目录"出发，不是从脚本位置**（跑脚本前先看提示符在哪个目录）；Windows 路径在 Python 里**统一用正斜杠** `/`，避开 `\u` 转义坑
- **程序的诚实**：0÷0 算不出就报 ZeroDivisionError、变量没赋值就用就报 NameError——程序宁可崩也不瞎猜；所以统计脚本要**先判断再计算**（无检查行就不算通过率）、**变量先给默认值**
- **验证思维**（延续 day7/day10）：跑通 ≠ 对。自动比对日志的"总结行"里也含 PASS/FAIL 字样，用 `"PASS:"`（带冒号）精准匹配检查行、跳过总结行——我自己观察格式发现的
- **构造测试数据**：为了验证 FAIL 功能，自己造一份含 FAIL 行的日志来测——"构造能触发目标情况的数据，看程序反应"（以后写 TB 也是这个思路）
- **数据流顺序 ≠ 写代码顺序**：环回（loop）在数据传输上位于 TX 和 RX 之间（TX→回环线→RX→loop→TX），但写代码必须先有 TX、RX 两端，桥才能架

## 今天我踩的坑（都改过来了）
- **print 参数漏逗号 ×2**：`print("PASS =" PASS)` 语法错误；print 每个参数之间必须逗号
- **相对路径 FileNotFoundError**：相对路径从终端当前目录出发；后来改用绝对路径 + 正斜杠
- **在 VS Code Python 交互窗口（`>>>`）里运行命令**：那不是终端，只认 Python 代码；运行脚本要 Ctrl+` 打开真正的终端（提示符 `PS`）
- **ZeroDivisionError**：PASS=0、FAIL=0 时直接 `PASS/(PASS+FAIL)` 除零崩溃；要先 `if PASS + FAIL == 0` 判断
- **NameError ×2（变量没赋值就用）**：`errors` 在日志无 `Errors:` 行时没赋值；`ERROR` 变量没初始化——都要开头给默认值
- **命名不一致**：判断 `"FAIL:"` 行却写成 `ERROR = ERROR + 1`（Verilog 老坑 IDEL/IDLE 的 Python 版），改为 `FAIL = FAIL + 1`
- **`\u` 转义坑**：路径写 `D:\uvm-...` 报 unicodeescape 错误；改 `D:/uvm-...` 正斜杠

## 打卡
- day14: Python 首练（parse_logs.py 三日志验证全过）+ 两周复盘 + 博客（待确认后发布）
