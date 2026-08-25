# 第 16 天总结：把 TB 散装数据打包成 uart_transaction 类——class 入门（2026-08-25）

## 今日目标（改造驱动：先做任务，用到才学）
把 tb_uart_top.sv 里 `expected_byte` 等散装数据打包成 `uart_transaction` 类：字段 data / parity_err / baud_div，方法 display()。完成标志：类能编译、display() 能打印字段、仿真照旧 3/3 PASS。

## 我做了什么
- **写了 uart_transaction 类**（放在 tb_uart_top.sv 最上面、module 外）：三个字段（8 位 data、1 位 bit parity_err、int baud_div）+ 构造函数 new(d, bd)（三字段全部初始化）+ display() 方法（打印三个字段）
- **改造主流程**：删掉 `expected_byte` 声明，换成句柄 `uart_transaction txn;`；每帧开头 `txn = new(8'hXX, 434);` + `txn.display();`；比对处 `expected_byte` → `txn.data`（6 处换干净）；发帧/等 rx_done/计数/等回显结构一律没动
- **验证**：vlog 编译 Errors 0 Warnings 0；仿真日志 3 行 `data = 01010101 / 10101010 / 00111100`（对应 0x55/0xAA/0x3C 的二进制）+ PASS 3, FAIL 0——行为与改造前完全一致

## 我学到的（class 入门三件套）
- **class = struct + 方法**：struct 只能打包数据，class 把数据和动作（方法）装进同一个盒子，盒子跟着数据走。一帧 = 一个 uart_transaction 对象，以后 generator/driver/scoreboard 之间传的就是它
- **class 三件套**：① 属性（class 里的变量）② 构造函数 new()（创建对象时自动调用，名字必须叫 new，负责给字段填初值）③ 方法（class 里的函数，能直接读写自己的属性）
- **对象使用四步**：声明句柄 → `new()` 创建 → 点号读属性（txn.data）→ 点号调方法（txn.display()）
- **句柄 = 取件码/遥控器**：句柄变量不装数据，只指向对象。**声明句柄 ≠ 有对象**——没 new 就是 null（空取件码），调方法会报错/全是 X
- **new 只分配不填值**：new 一定会造出对象，但字段初值要自己赋——漏赋的话 logic 是 X、bit/int 是 0
- **module vs class**：module 是电路（有端口有时钟，综合成硬件，例化=接线，静态的）；class 是软件模板（不综合，new 才造对象，动态的）。module 不能 new，class 不能例化
- **函数参数是本地变量**：new 的形参（d、bd）只在 new 内部有效，display 里想用只能用类属性 baud_div
- **new 的参数要和字段同宽**：data 是 8 位，参数 d 也得 [7:0]，不然 8 位数据塞 1 位参数
- **句柄重定向**：每帧 `txn = new(...)` 让 txn 指向新对象，display 打印的就是 txn 当前指向的那个对象——三帧三个对象，打印分别是 55/AA/3C

## 今天我踩的坑（都改过来了）
1. **parity_err 写成 `logic [1:0]`**：`[1:0]` 是 2 位，规格要 1 位；且应选 bit（2 态默认 0，不接 DUT 信号不需要 X 检测）
2. **new 的参数 d 写成裸 `logic`**（1 位）：要和它存的字段 data 同宽 `logic [7:0]`，否则位宽对不上
3. **display 里用了 `bd`**：bd 是 new 的形参，出了 new 就没了（作用域），编译必报未声明——用类属性 baud_div
4. **第 2、3 帧漏 `txn.display()`**：第 1 帧改全了，复制时把 display 漏掉（第 10 天"复制粘贴三件套"老坑重现）——仿真日志里 `data =` 只打了 1 行被抓出，3 帧该 3 行。数日志行数就是自查方法
5. **三个术语没听懂就要追着问**：parity_err（奇偶校验错误标记）、baud_div（一个数据位占的时钟周期数，115200 波特率 = 434）、txn 句柄——一开始没解释到位，我追问到彻底明白才动手。不懂就问，一次问清，别憋着

## 明天的引子
第 17 天把 TB 拆成 generator 和 driver 两个类：generator 负责产生激励（造 uart_transaction 对象）、driver 负责时序驱动（发帧），中间用队列通信（第 15 天认识的 push_back/pop_front）。今天造好的 uart_transaction 就是它们之间传的"包裹"。

## 打卡
- day16: uart_transaction 类（data/parity_err/baud_div + new + display）+ TB 散装 expected_byte → txn.data 改造 + sv-practice/class_example.sv（教学例子）+ summary-day16
