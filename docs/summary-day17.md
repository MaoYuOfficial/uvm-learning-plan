# Day 17 学习总结：Generator、Driver 和 Queue

> 学习日期：2026-09-02
> 主题：把测试流程拆成 Generator 和 Driver，并用 queue 传递 transaction

## 一、今天完成了什么

今天在 Day 16 的 `uart_transaction` 基础上，把测试流程拆成了两个 class：

- `uart_generator`：负责创建 transaction 数据；
- `uart_driver`：负责从队列中取出 transaction 并处理；
- `queue`：负责在 Generator 和 Driver 之间传递 transaction。

我没有直接修改原来的大型 UVM TB，而是新建了独立练习文件：

```text
D:/uvm-learning-plan/sv-practice/day17_generator_driver.sv
```

## 二、我写出的主要结构

```text
module tb_day17
├── gen = new()
│   └── uart_generator 对象
├── drv = new()
│   └── uart_driver 对象
├── gen.generate_transactions()
│   └── 生成 55、AA、3C 并放入 queue
└── drv.drive(gen.queue)
    └── 用 pop_front() 依次取出 transaction
```

## 三、关键知识

### 1. Generator 和 Driver 的职责

- Generator 管“产生什么数据”；
- Driver 管“取出数据并执行处理”；
- 两者不再把所有工作写在同一个过程里。

这样以后如果要把固定数据改成随机数据，主要修改 Generator；如果要修改发送时序，主要修改 Driver。

### 2. queue

SystemVerilog 中的 queue 是动态队列，今天使用的是先进先出 FIFO：

```systemverilog
uart_transaction queue[$];
```

- `push_back(t)`：把 transaction 放到队尾；
- `pop_front()`：从队头取出最早放入的 transaction；
- `queue.size()`：查看当前队列中有多少个元素。

### 3. Driver 中的 while

```systemverilog
while (queue.size() != 0) begin
    t = queue.pop_front();
    #10;
    $display("Driver: drive data=%h", t.data);
end
```

意思是：只要队列不为空，就继续取出并处理 transaction。队列变为空后，`while` 自动结束。

### 4. ref

```systemverilog
task drive(ref uart_transaction queue[$]);
```

`ref` 让 Driver 操作调用者传入的原队列。Driver 每执行一次 `pop_front()`，Generator 的 `gen.queue` 也会同步减少一个元素。

### 5. class 对象和句柄

```systemverilog
uart_generator gen;
gen = new();
```

`gen` 是句柄，`new()` 创建真正的 `uart_generator` 对象。`uart_driver drv` 也是同样的道理。

## 四、今天遇到并修正的问题

### 问题 1：构造函数赋值方向写反

错误写法：

```systemverilog
d = data;
b_div = baud_div;
```

正确写法：

```systemverilog
data = d;
baud_div = b_div;
```

左边是对象中的类属性，右边是传入的构造函数参数。

### 问题 2：把 `always` 和 `while` 混用

Driver 中不能写：

```systemverilog
while if (queue.size() != 0)
```

也不能把 `always` 直接写在 task 中。今天应使用：

```systemverilog
while (queue.size() != 0) begin
    ...
end
```

### 问题 3：`while` 后面不能接 `else`

`else` 只能和 `if` 配对，不能直接跟在 `while` 后面。队列为空后，`while` 循环会自然结束。

### 问题 4：访问字段时写成 `t.d`

构造函数中的 `d` 只是临时形参，类中长期保存的数据字段叫 `data`，所以 Driver 中要写：

```systemverilog
$display("Driver: drive data=%h", t.data);
```

而不是：

```systemverilog
$display("Driver: drive data=%h", t.d);
```

## 五、可视化仿真结果

在 ModelSim 图形界面中运行成功，Transcript 输出为：

```text
Driver: drive data=55
Driver: drive data=aa
Driver: drive data=3c
Queue is empty
Final queue size = 0
```

并且 ModelSim 显示：

```text
** Note: $finish
Time: 30 ns
```

三帧之间各等待 `#10`，因此总仿真时间为：

```text
3 × 10 ns = 30 ns
```

`Final queue size = 0` 证明 Driver 已经把队列里的三帧全部取出。

## 六、今天的完成标志

我现在能够说出：

> **Generator 管数据，Driver 管处理流程，Queue 负责在两者之间传递 transaction。**

Day 17 的目标已经完成。

## 七、当前练习的范围

今天的 Driver 只是模拟处理流程：

```text
取出 transaction → 延时 #10 → 打印 data
```

目前还没有真正连接 UART 的 `clk`、`tx_data`、`tx_wr_en` 等 DUT 信号，也没有形成真实 UART 波形；这些内容留到后续 TB 改造阶段。
