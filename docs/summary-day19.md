# Day 19 学习总结：Transaction 随机化与约束

> 学习日期：2026-09-05
> 主题：SystemVerilog 的 `rand`、`randc`、`constraint`、`randomize()` 和受约束随机验证

## 一、今天完成了什么

今天在前几天 `uart_transaction`、generator、继承和多态的基础上，创建了一个用于随机验证的 transaction：

```systemverilog
class uart_random_transaction;
    rand bit [7:0] data;
    randc int frame_pos;
    rand bit parity_err;
    rand int baud_div;
endclass
```

完成了以下内容：

- 理解为什么验证环境不能只依赖手工写死的 `8'h55`、`8'hAA` 等测试数据；
- 学习 `rand`，让字段能够在调用 `randomize()` 时被随机赋值；
- 学习 `randc`，让 `frame_pos` 在一轮合法值内不重复；
- 使用约束限制 `data` 至少包含两个二进制 `1`；
- 使用 `frame_pos` 和约束关系实现每 10 帧恰好 1 个错误帧；
- 使用 `inside` 将 `baud_div` 限制在 `434`、`217`、`109` 三个合法值中；
- 使用 `if/else` 检查 `randomize()` 的返回值；
- 连续随机化 20 次并通过 ModelSim 验证。

本次练习文件：

```text
D:/uvm-learning-plan/sv-practice/day19_random_constraint.sv
```

## 二、今天写出的主要结构

```text
uart_random_transaction
├── rand data          ：随机 8 位数据
├── randc frame_pos   ：0~9 一轮不重复的帧位置
├── rand parity_err   ：随机错误标志，由约束决定最终值
├── rand baud_div     ：随机分频值，由 inside 限制合法集合
└── data_limit        ：统一约束

 tb_day19
 ├── tr = new()       ：创建 transaction 对象
 ├── repeat (20)      ：执行 20 次
 ├── tr.randomize()   ：每次生成一组满足约束的值
 └── if/else          ：判断随机化是否成功
```

## 三、关键知识

### 1. 为什么需要受约束随机

如果每个 transaction 都手工指定：

```systemverilog
t = new(8'h55, 434);
t = new(8'hAA, 434);
```

测试数据数量一多，就很难覆盖各种情况。

受约束随机的思想是：

```text
让工具自动产生不同输入，但每个输入必须符合验证者规定的规则。
```

随机化不是“完全没有规则地乱取值”，而是：

```text
随机生成 + 必须满足约束
```

### 2. `rand`

```systemverilog
rand bit [7:0] data;
```

`rand` 表示这个成员允许在调用对象的 `randomize()` 方法时被随机赋值。

但是写了 `rand` 后变量不会自动变化，必须先有对象，再调用方法：

```systemverilog
uart_random_transaction tr;  // 声明句柄
tr = new();                  // 创建对象
tr.randomize();              // 对 tr 指向的对象进行随机化
```

`rand` 每次是独立随机的，允许重复。例如连续几次可能得到：

```text
51、2b、51
```

### 3. `randc`

```systemverilog
randc int frame_pos;
```

`randc` 中的 `c` 是 cyclic，表示循环随机。

今天把它限制在 `0~9`：

```systemverilog
frame_pos >= 0;
frame_pos <= 9;
```

因此连续 10 次随机化时，`frame_pos` 会把 `0~9` 每个值使用一次后，再开始下一轮。

今天实际观察到的第一轮是：

```text
0、3、1、9、6、4、7、8、5、2
```

排序后正好是：

```text
0、1、2、3、4、5、6、7、8、9
```

第二轮也同样各出现一次。

`randc` 不是永远不重复，而是：

> 在当前一轮合法值没有全部使用完之前不重复；一轮结束后可以重新开始。

### 4. `constraint`

```systemverilog
constraint data_limit {
    ...
};
```

`constraint` 是给随机约束求解器的规则，不是按照顺序执行的过程代码。

例如：

```systemverilog
$countones(data) >= 2;
```

要求随机得到的 `data` 至少包含两个 `1`。

这里的 `$countones(data)` 会统计 `data` 中二进制 `1` 的数量。

### 5. 约束中为什么使用 `==` 而不是 `=`

在过程代码中：

```systemverilog
parity_err = 1;
```

`=` 是赋值，表示现在立刻把变量改成 `1`。

在约束中：

```systemverilog
parity_err == 1;
```

`==` 是相等关系，表示随机化结果必须满足“`parity_err` 等于 `1`”。

所以：

```text
过程代码：parity_err = 1;   // 执行赋值
约束代码：parity_err == 1;  // 描述必须相等
```

今天用 ModelSim 10.4 做了最小验证，将约束中的 `==` 改成 `=` 后，编译得到：

```text
Invalid use of assignment expression in constraint.
```

因此不能在这个约束中用 `=` 代替 `==`。

### 6. 用 `frame_pos` 控制错误帧

```systemverilog
(frame_pos == 0) -> (parity_err == 1);
(frame_pos != 0) -> (parity_err == 0);
```

第一条表示：

```text
如果 frame_pos 等于 0，那么 parity_err 必须等于 1。
```

第二条表示：

```text
如果 frame_pos 不等于 0，那么 parity_err 必须等于 0。
```

因为 `randc frame_pos` 在每 10 次中恰好出现一次 `0`，所以每 10 帧恰好有一个错误帧。

### 7. `inside`

```systemverilog
baud_div inside {434, 217, 109};
```

`inside` 表示成员必须属于大括号中的合法集合。

所以 `baud_div` 只能取：

```text
434、217、109
```

`baud_div` 声明为 `rand`，因此这些值可以重复；它不像 `frame_pos` 那样要求一轮内不重复。

### 8. `randomize()` 的对象来源

不能孤立地只写：

```systemverilog
tr.randomize();
```

完整关系是：

```systemverilog
uart_random_transaction tr;  // tr 是句柄
tr = new();                  // 创建对象
tr.randomize();              // 调用这个对象的方法
```

`tr` 不是关键字，只是对象句柄的变量名，也可以叫 `tx`。

### 9. `if (tr.randomize() == 0)` 的执行顺序

```systemverilog
if (tr.randomize() == 0) begin
    $display("Randomization Failed");
end
else begin
    $display("...", tr.data);
end
```

执行顺序是：

```text
1. 先调用 tr.randomize()
2. randomize() 尝试生成并写入一组合法字段
3. randomize() 返回 1 或 0
4. 判断返回值是否等于 0
5. 返回 0 进入 if，返回 1 进入 else
```

所以不需要在 `if` 前面再随机化一次。`if` 条件里的函数调用本身就已经完成了随机化。

如果写成：

```systemverilog
tr.randomize();
if (tr.randomize() == 0) begin
```

就会在每一轮随机化两次：第一次结果被丢弃，第二次才被判断和打印。这还会额外消耗 `randc` 的循环值，并产生未检查返回值的 warning。

## 四、最终代码中的关键部分

```systemverilog
class uart_random_transaction;
    rand bit [7:0] data;
    randc int frame_pos;
    rand bit parity_err;
    rand int baud_div;

    constraint data_limit {
        $countones(data) >= 2;
        frame_pos >= 0;
        frame_pos <= 9;
        (frame_pos == 0) -> (parity_err == 1);
        (frame_pos != 0) -> (parity_err == 0);
        baud_div inside {434, 217, 109};
    };
endclass
```

```systemverilog
initial begin
    tr = new();

    repeat (20) begin
        if (tr.randomize() == 0) begin
            $display("Randomization Failed");
        end
        else begin
            $display(
                "data = %h, frame_pos = %0d, baud_div = %0d, parity_err = %0b",
                tr.data,
                tr.frame_pos,
                tr.baud_div,
                tr.parity_err
            );
        end
    end

    $finish;
end
```

## 五、ModelSim 验证结果

实际验证使用：

```text
ModelSim SE-64 10.4
```

最终验证结果：

```text
vlog：Errors: 0, Warnings: 0
vsim：Errors: 0, Warnings: 0
```

共随机化 20 次：

- 没有出现 `Randomization Failed`；
- `data` 满足至少包含两个 `1`；
- 前 10 次 `frame_pos` 各取 `0~9` 一次；
- 后 10 次 `frame_pos` 也各取 `0~9` 一次；
- 两轮中各有一次 `frame_pos = 0, parity_err = 1`；
- 其他帧均为 `parity_err = 0`；
- `baud_div` 始终属于 `434`、`217`、`109`；
- `$finish` 是正常结束仿真的提示；
- 仿真时间为 `0 ns`，因为代码中没有 `#10` 等时间延迟。

## 六、今天遇到并解决的问题

### 问题 1：一开始误把 `$countones()` 归因成 ModelSim 错误

实际报错行是：

```systemverilog
$frame_pos >= 0;
$frame_pos <= 9;
```

错误原因是把普通变量 `frame_pos` 错写成了带 `$` 的系统函数形式。

正确写法：

```systemverilog
frame_pos >= 0;
frame_pos <= 9;
```

`$countones(data)` 实际上可以在当前 ModelSim 版本的约束中正常使用。

### 问题 2：旧的 `tr.randomize()` 没有删除

把循环从 10 次改成 20 次时，旧的：

```systemverilog
tr.randomize();
```

曾经留在 `if` 前面，造成每轮随机化两次。

修正后每轮只保留：

```systemverilog
if (tr.randomize() == 0) begin
```

### 问题 3：随机化结果是否需要在判断前单独生成

不需要。下面这一行已经是“调用随机化并判断返回值”：

```systemverilog
if (tr.randomize() == 0)
```

`else` 读取的是同一次 `randomize()` 成功后写入 `tr` 对象的字段。

## 七、今天的完成标志

我现在能够用自己的话解释：

> `rand` 允许字段被随机化，`randc` 让字段在一轮合法值内不重复，`constraint` 规定随机结果必须满足的条件，`randomize()` 负责实际求解并生成一组合法值。

我还能够解释：

```systemverilog
if (tr.randomize() == 0)
```

为什么不需要在 `if` 前面再调用一次 `tr.randomize()`。

Day 19 已完成。

## 八、下一步

下一次先复习：

```text
rand / randc
constraint
inside
-> 关系约束
randomize() 返回值
if/else
```

然后进入 Day 20：

- 在 generator 中随机产生 transaction；
- 将随机 transaction 发送给 driver；
- 用 Python 生成全 0、全 1、交替、单 bit 翻转等边界数据；
- 让随机激励和定向边界数据一起验证 DUT。