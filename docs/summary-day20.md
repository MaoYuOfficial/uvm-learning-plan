# Day 20 学习总结：generator 随机产生 transaction + Python 助阵

> 学习日期：2026-09-06
> 主题：随机模式与定向模式、每个 transaction 必须一次 new、句柄与对象、用 Python 生成边界数据清单

## 一、今天完成了什么

今天在 Day 17 generator/driver 结构和 Day 19 随机约束的基础上，把验证激励做成了**两条腿走路**：

- 定向模式：手工指定边界值（全 0 / 全 1 / 交替 / 单 bit 翻转），保证关键角落必测；
- 随机模式：调用 `randomize()`，让求解器在约束范围内自由取值，负责广度覆盖；
- 用 Python 脚本生成 12 个定向边界值的可直接粘贴代码，替代手抄。

完成了以下内容：

- 理解为什么光有随机不够：Day 19 的约束 `$countones(data) >= 2` 会把全 0（8'h00）和单 bit 值（8'h01 等）永远排除在外，全 1（8'hFF）也很难被随机抽中；
- 学会定向模式：`new` 之后手工逐个给字段赋值，全程不调用 `randomize()`，约束管不着；
- 把 Day 17 的 generator 改造成"定向 4 帧 + 随机 5 帧"双路径；
- 用 Python 生成单 bit 翻转清单（`1 << i` 产生 8'h01~8'h80），把定向段扩展到 12 帧；
- ModelSim 验证通过，Log 里同时看到 12 个定向值和 5 个各不相同的随机值。

本次练习文件：

```text
D:/uvm-learning-plan/sv-practice/day20_random_directed_generator.sv
D:/uvm-learning-plan/python-practice/day20_boundary_list.py
```

## 二、今天写出的主要结构

```text
uart_random_transaction（含 Day 19 的约束 + 4 参数构造函数）
 ├── rand  data        ：随机 8 位数据
 ├── randc frame_pos   ：0~9（注意：每帧是新对象，见"问题 5"）
 ├── rand  parity_err  ：frame_pos 抽到 0 就是错误帧
 └── rand  baud_div    ：inside 限制 434/217/109

uart_generator
 ├── 定向段：12 帧，new + 手工赋值，不碰 randomize()
 └── 随机段：repeat (5)，每轮 new 新对象再 randomize()

uart_driver
 └── while + pop_front，每帧 #10 后打印

python-practice/day20_boundary_list.py
 ├── values 清单：00/FF/55/AA + 1<<i 生成 01~80
 └── 打印 24 行可直接粘贴的 SV 代码
```

## 三、关键知识

### 1. 随机模式 vs 定向模式

| | 随机模式 | 定向模式 |
|---|---|---|
| 数据怎么来 | 调用 `tr.randomize()`，求解器按约束挑值 | 不调用 `randomize()`，手工给字段赋值 |
| 负责什么 | 广度：意想不到的组合 | 深度：指定边界值必测 |

最重要的一句话：**约束只在调用 `randomize()` 的时候才生效**。约束不是保安，不会时时刻刻盯着变量；它是求解器的说明书，只有 `randomize()` 被调用时才被读取。所以定向段直接写 `tr.data = 8'h00;` 完全合法——全 0 就写进去了。

### 2. 每个 transaction 必须 new 一次（今天最大的坑）

队列里存的是**句柄**（门牌号），不是对象的复印件。同一轮循环里如果忘了 `t = new(...)`，5 轮 `randomize()` 反复改写的都是**同一个对象**，队列里 6 个位置指向它，最后 6 行打印出一模一样的值（第一版代码实际打出了 6 遍 `7e`，`aa` 反而消失了）。

`randomize()` 是"就地改写"对象，不产生新对象。想要 5 个不同的随机 transaction，必须 new 5 次。这也是 generator/driver 拆开之后"每帧必须 new 一次"成为铁律的原因：Day 19 只有一个 `tr` 用完即扔，覆盖了无所谓；Day 20 把对象攒进队列，覆盖问题立刻现形。

### 3. 构造函数与 new 的规则

- SystemVerilog **不支持函数重载**：一个类只能有一个 `new`，签名定了就得按签名调用；
- `rand` / `randc` 是贴在 class 成员变量上的修饰符，**不能**写进函数参数列表（写了直接语法错误，参数只允许 input/output/inout/ref 方向）；
- 保留 4 参构造函数时，随机帧的写法是：`t = new(8'h00, 1, 0, 434);` 占位，紧接着 `randomize()` 会把 4 个 rand 字段全部重新求解覆盖，占位值一个都留不下来——"先 new 再 randomize"是标准写法。

### 4. Python 助阵：生成定向清单

- Python 不参与仿真，只负责**打印 24 行可直接粘贴的 SV 代码**（"代抄工"）；
- `1 << i`：二进制左移，"只有第 i 位是 1"的值——i 从 0 到 7 正好生成 8 个单 bit 翻转值 01~80；
- `f"{v:02x}"`：花括号是窗口，冒号后面是打扮要求——`x` 按十六进制，`02` 至少两位不足补 0（和 `$display` 的 `%02h` 是双胞胎）；
- `values.append(x)`：往清单末尾加一项，同 SV 的 `queue.push_back(t)`；
- `for i in range(8)`：i 的出生地就在 for 这一行，一圈发一张牌 0~7，Python 替你干了 SV 里"声明、起始、判断、加一"四件事。

### 5. randc 的账本是每个对象一份（修正了之前的一个错误理解）

之前以为"5 帧随机的 frame_pos 互不重复是 randc 在起作用"——实际输出两次打脸（一次 `6,6,8,3,4`，一次 `8,2,0,9,0`）。

真正机制：randc 的"一轮不重复"是**每个对象自己的账本**。Day 19 同一个对象连抽 20 次，一本账记满 0~9 才翻新，所以恰好"每 10 帧一次 0"。Day 20 每帧都是新对象，各带一本空白账，只抽一次就进队列，5 个对象互不相干，重复和多个错误帧都正常。

结论：**"每 10 帧恰好 1 个错误帧"这个特性在"每帧新建对象"的结构里暂时不存在了**，错误帧变成"每个新对象独立抽签，抽到 0 就是错误帧"。找回这个特性需要重新设计错误注入方式，留到后面需要它的时候。

## 四、最终代码中的关键部分

```systemverilog
// 定向段（由 Python 生成后粘贴）：12 帧，每帧两行
t = new(8'h00, 1, 0, 434);
queue.push_back(t);
t = new(8'hff, 1, 0, 434);
queue.push_back(t);
// …… 55 / aa / 01 / 02 / 04 / 08 / 10 / 20 / 40 / 80

// 随机段：每轮先 new 新对象，再随机化
repeat (5) begin
    t = new(8'h00, 1, 0, 434);
    if (t.randomize() == 0) begin
        $display("Randomization Failed");
    end
    else begin
        queue.push_back(t);
    end
end
```

```python
# day20_boundary_list.py
values = [0x00, 0xFF, 0x55, 0xAA]
for i in range(8):
    values.append(1 << i)
for v in values:
    print(f"t = new(8'h{v:02x}, 1, 0, 434);")
    print("queue.push_back(t);")
```

## 五、ModelSim / Python 验证结果

```text
Python：day20_boundary_list.py 实跑输出 24 行，内容正确
vlog：Errors: 0, Warnings: 0
vsim：Errors: 0, Warnings: 0
```

最终一轮 Log（17 帧 = 12 定向 + 5 随机，170 ns）：

```text
定向 12 帧：0、ff、55、aa、1、2、4、8、10、20、40、80（全部按序原样出现）
随机 5 帧：9f、dc、93、6c、69（各不相同，data 都至少 2 个 1）
这一轮 frame_pos = 8、2、0、9、0，出现两个 0 → 两个 parity_err = 1 的错误帧
Queue is empty / Final queue size = 0
```

## 六、今天遇到并解决的问题

### 问题 1：`rand` 写进构造函数参数，编译报错

```text
** Error: near "rand": syntax error, unexpected rand.
```

参数列表只允许 input/output/inout/ref 方向，`rand`/`randc` 只能贴在 class 成员变量上。

### 问题 2：`t = new();` 和 4 参构造函数冲突

类里写了 4 参构造函数后，无参的 `new()` 就非法了——SV 不支持函数重载。解决：保留构造函数，随机帧也用 4 参调用（占位值会被 randomize 全部覆盖）。

### 问题 3：`$finish` 漏分号

编译报 near "end"。语法错误一次只报第一个，要改一个、重编译一次，逐个消灭。

### 问题 4：随机循环里删掉了 `t = new(...)`，打出 6 遍相同的 7e

队列存的是句柄不是复印件；忘了 new，5 轮随机化反复揉搓同一个对象，aa 被覆盖消失。修复：循环里每轮先 `t = new(...)`。

### 问题 5：误以为 5 帧随机的 frame_pos 不会重复

randc 账本每个对象一份，新对象各抽各的，重复正常（详见"关键知识 5"）。

## 七、今天的完成标志

我现在能够用自己的话解释：

> 随机模式靠 `randomize()` 让求解器按约束挑值，负责广度；定向模式手工赋值、不碰求解器，负责把全 0、全 1、单 bit 这些约束够不着的角落测到。
> 队列里存的是句柄，每个 transaction 必须 new 一次；randomize() 是就地改写，不产生新对象。
> randc 的"一轮不重复"是每个对象自己的账本，新对象各抽各的。

Day 20 已完成。

## 八、下一步

下一次先复习：

```text
随机模式 vs 定向模式
句柄与对象（队列存句柄）
randc 账本 per-object
Python 生成清单的套路
```

然后进入 Day 21（复盘 + 开始每天投实习）：口述"generator → driver → DUT"数据流，把项目进展写成 3 行放进简历草稿，注册实习僧 / Boss 直聘投出第一份实习。
