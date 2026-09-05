# Day 18 学习总结：Transaction 继承、多态与虚方法

> 学习日期：2026-09-04
> 主题：SystemVerilog 的继承、`super`、`virtual` 和多态

## 一、今天完成了什么

今天在 Day 17 的 `uart_transaction` 基础上，创建了一个错误 transaction 子类：

```systemverilog
class error_transaction extends uart_transaction;
```

完成了以下内容：

- 复习父类 `uart_transaction` 的字段和构造函数；
- 使用 `extends` 创建 `error_transaction` 子类；
- 在子类中新增 `force_error` 字段；
- 使用 `super.new(d, b_div)` 调用父类构造函数；
- 在子类构造函数中设置 `force_error = 1` 和 `parity_err = 1`；
- 使用 `virtual function void display()` 重写父类的 `display()`；
- 使用父类句柄 `tr` 先后指向普通对象和错误对象；
- 通过 ModelSim 仿真验证多态行为。

本次练习文件：

```text
D:/uvm-learning-plan/sv-practice/day18_inheritance_polymorphism.sv
```

## 二、今天写出的主要结构

```text
uart_transaction 父类
├── data
├── parity_err
├── baud_div
├── new()
└── virtual display()

error_transaction 子类
├── 继承父类字段和方法
├── force_error
├── new()
│   └── super.new(d, b_div)
└── 重写 display()

tb_day18
├── normal_tr
├── err_tr
└── tr（父类句柄）
    ├── 先指向 normal_tr
    └── 再指向 err_tr
```

## 三、关键知识

### 1. 继承 `extends`

```systemverilog
class error_transaction extends uart_transaction;
```

表示 `error_transaction` 是 `uart_transaction` 的子类。

子类对象包含父类部分，因此可以直接使用父类已经定义的：

```text
data
parity_err
baud_div
```

子类还可以增加自己的字段和方法，例如：

```systemverilog
bit force_error;
```

继承的作用是复用父类已有内容，同时扩展新的功能。

### 2. `super`

在子类内部，`super` 表示父类部分。

```systemverilog
super.new(d, b_div);
```

表示调用父类 `uart_transaction` 的构造函数，先初始化继承来的字段：

```text
data
parity_err
baud_div
```

然后子类再继续初始化自己的字段：

```systemverilog
force_error = 1;
parity_err  = 1;
```

`super` 不是新建一个对象，而是调用父类的构造函数或方法。

### 3. `virtual`

父类中的方法写成：

```systemverilog
virtual function void display();
```

`virtual` 允许子类重写该方法，并让调用结果根据对象的实际类型动态决定。

```systemverilog
tr = normal_tr;
tr.display();

tr = err_tr;
tr.display();
```

两次都是调用：

```systemverilog
tr.display();
```

但是第一次执行父类版本，第二次执行子类版本。

### 4. 多态

多态的关键代码是：

```systemverilog
uart_transaction tr;
tr = err_tr;
tr.display();
```

此时：

```text
tr 的声明类型：uart_transaction
tr 实际指向的对象：error_transaction
```

由于父类的 `display()` 是 `virtual`，所以最终执行子类的 `display()`。

可以把多态记成：

> 父类句柄可以指向不同类型的对象，调用同名虚方法时，会执行实际对象对应的版本。

### 5. `void`

```systemverilog
virtual function void display();
```

这里的 `void` 表示 `display()` 只执行打印操作，不返回结果。

`new()` 是构造函数，属于特殊函数，不需要写 `void`。

## 四、实际代码中的关键部分

父类方法：

```systemverilog
virtual function void display();
    $display(
        "Normal transaction: data = %0b parity_err = %0b baud_div = %0d",
        data,
        parity_err,
        baud_div
    );
endfunction
```

子类构造函数和方法：

```systemverilog
function new(bit [7:0] d, int b_div);
    super.new(d, b_div);

    force_error = 1;
    parity_err  = 1;
endfunction

virtual function void display();
    $display(
        "Error transaction: data = %0b parity_err = %0b baud_div = %0d force_error = %0b",
        data,
        parity_err,
        baud_div,
        force_error
    );
endfunction
```

多态测试：

```systemverilog
normal_tr = new(8'h55, 434);
tr = normal_tr;
tr.display();

err_tr = new(8'hAA, 434);
tr = err_tr;
tr.display();
```

## 五、ModelSim 仿真结果

仿真输出为：

```text
Normal transaction: data = 1010101 parity_err = 0 baud_div = 434
Error transaction: data = 10101010 parity_err = 1 baud_div = 434 force_error = 1
** Note: $finish
Time: 0 ns  Iteration: 0  Instance: /tb_day18
```

结果说明：

- 普通对象调用了父类 `display()`；
- 错误对象通过父类句柄调用了子类 `display()`；
- `parity_err = 1` 和 `force_error = 1` 说明错误 transaction 的扩展字段已正确初始化；
- `$finish` 是主动结束仿真的正常提示，不是报错；
- 当前代码没有 `#10` 等时间延迟，因此仿真时间为 `0 ns`。

## 六、今天遇到并澄清的问题

今天的主要困难不是代码结构本身，而是几个关键 SystemVerilog 概念一开始没有解释清楚。经过提问和修改，已经完成以下澄清。

### 问题 1：`virtual` 到底做什么

一开始把：

```systemverilog
function virtual_display();
```

误认为是和虚方法有关的写法。

正确写法是：

```systemverilog
virtual function void display();
```

`virtual` 不是函数名的一部分，而是函数修饰关键字。它的作用是支持多态：当父类句柄指向子类对象时，调用同名方法可以根据实际对象类型选择正确的版本。

```systemverilog
uart_transaction tr;

tr = normal_tr;
tr.display();       // 调用父类 display()

tr = err_tr;
tr.display();       // 调用子类 display()
```

记忆方式：

```text
没有 virtual：主要看句柄声明类型
有 virtual：根据实际指向的对象类型调用方法
```

### 问题 2：`void` 什么时候用，什么时候不用

```systemverilog
virtual function void display();
```

这里的 `void` 表示 `display()` 只执行打印操作，不返回结果。

如果函数需要返回结果，就要写具体返回类型：

```systemverilog
function int add(int a, int b);
    return a + b;
endfunction
```

```systemverilog
function bit is_error();
    return parity_err;
endfunction
```

判断方法是：

```text
调用者不需要接收结果 → 使用 void
调用者需要接收结果   → 使用 int、bit、bit [7:0] 等具体类型
```

`new()` 是特殊的构造函数，不需要写 `void`；`task` 也不使用函数返回类型，适合包含 `#10`、事件等待等时序操作。

### 问题 3：`super` 到底是什么

在子类内部：

```systemverilog
super
```

表示当前对象中的父类部分。

```systemverilog
super.new(d, b_div);
```

表示调用父类 `uart_transaction` 的构造函数，先初始化继承来的：

```text
data
parity_err
baud_div
```

然后再执行子类自己的初始化：

```systemverilog
force_error = 1;
parity_err  = 1;
```

`super` 不会新建一个独立的父类对象。子类对象中本来就包含父类部分，`super.new()` 只是初始化这同一个对象里的父类字段。

此外，`super` 也可以调用父类方法，例如：

```systemverilog
super.display();
```

而：

```systemverilog
this
```

表示当前对象本身。可以记成：

```text
this  = 当前对象
super = 父类部分
```

### 问题 4：类名和对象句柄不能混用

曾经出现过类似：

```systemverilog
error_transaction = new();
```

其中 `error_transaction` 是类名，不能接收对象。正确的对象句柄是声明出来的：

```systemverilog
error_transaction err_tr;
err_tr = new(8'hAA, 434);
```

创建对象时还必须传入子类构造函数要求的参数。

### 问题 5：为什么 `8'h55` 打印成 `1010101`

代码使用了：

```systemverilog
%0b
```

`%0b` 会抑制前导零，因此 `8'h55` 的完整二进制：

```text
01010101
```

会显示为：

```text
1010101
```

这不是数据错误。若想固定显示 8 位，应使用：

```systemverilog
%08b
```

若想使用更适合 UART 数据的十六进制显示，可以使用：

```systemverilog
%02h
```

## 七、今天的完成标志

我现在能够说明：

> `extends` 用于继承，`super.new()` 用于调用父类构造函数，`virtual` 用于支持多态，父类句柄指向子类对象后可以调用子类重写的方法。

Day 18 已完成。

## 八、下一步

下一次学习前，我会先复习今天的四个核心概念：

```text
extends      ：子类继承父类
super.new()  ：调用父类构造函数
virtual      ：支持父类句柄调用子类重写的方法
多态         ：同一个父类句柄可以指向不同类型的对象
```

我还要能够用自己的话解释下面这段代码：

```systemverilog
tr = normal_tr;
tr.display();

tr = err_tr;
tr.display();
```

也就是：同一个父类句柄 `tr` 先后指向普通 transaction 和错误 transaction，并通过 `virtual display()` 调用各自的实现。

Day 18 的代码和仿真练习已经完成，下一次学习再进入新的内容。