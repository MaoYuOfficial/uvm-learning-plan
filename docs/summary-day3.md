# day 3 总结

## 做了什么
- 学时序逻辑：RS 触发器（与非门交叉反馈）、锁存器 vs 触发器、主从结构、同步/异步复位、D 触发器波形
- HDLBits 刷完 Latches and Flip-Flops 整个章节 10 题：dff / dff8 / dff8r（复位值 0x34）/ dff8p / dff8ar / dff16e（字节使能）/ D Latch / 主从 DFF / DFF+gate
- 💬 练习：D 触发器波形题（t2 沿变 1、t5 沿变 0，完成标志达成）；锁存器 vs 触发器区别

## 踩的坑（重点）
1. **`if(a = b)` 是赋值不是比较！** `=` 赋值、`==` 比较。`if(a=1)` 永远为真，编译不报错但逻辑全错——Verilog 第一大坑
2. **异步复位必须进敏感列表**：`always @(posedge clk or posedge areset)`；同步复位列表只有 clk。对比记忆：dff8r（同步）vs dff8ar（异步）
3. **resetn 低有效**：名字带 n = negative = 低有效，`if(!resetn)` 才复位，写 `if(resetn)` 正好相反
4. **byteena 逐位控制**：byteena[0] 管低字节、byteena[1] 管高字节，不能拿整个 2 位向量和 1 比较
5. **`=` 立即生效（组合用），`<=` 沿到统一更新（时序用）**：交换例子——`a<=b; b<=a` 真交换；`a=b; b=a` 两个都变旧 b
6. **Verilog 无顺序无循环**：module 里 assign/always 全并行，assign 是硬连线随时算，always 只在沿上动；顺序无关
7. **复位值别算错进制**：0x34 = 52 = 8'h34（不是 8'd34！）
8. **begin...end 打包**：if/else 后面默认只跟一条语句，多条必须 begin...end 包（= C 的 {}）

## 关键公式/知识点
- RS 触发器：S=Set 置位、R=Reset 复位；与非门交叉反馈 = 记忆的来源；约束 S̄·R̄=0（两个输入不能同时为 0 → 不定态）
- 记忆原理：输出反馈回输入，闭合回路 → 输出依赖自己的过去状态
- 锁存器 = 电平触发（ena=1 透明跟随，会偷看）；触发器 = 边沿触发（只在 posedge 瞬间采样，抗干扰）
- 主从结构（两个锁存器，下降沿输出）≠ 边沿触发（上升沿采样）——两种实现方案
- D 触发器黄金规则：只在上升沿瞬间看 D，沿之间 Q 保持不动
- 同步复位 = 沿 + reset 都满足才清；异步复位 = reset 一变就清（不等 clk）
- 时序逻辑：没被赋值的寄存器 = 保持原值（不是 latch！latch 是组合逻辑的坑，第 4 天 always_nolatch 见）
- RTL 写行为、综合工具选结构：主从触发器代码 = 普通 DFF，内部结构不用管
- 同步时序电路标准范式：组合块算次态（assign）+ 时序块存现态（always posedge）——第 30 讲核心，状态机骨架
- 全加器 cout 是三变量多数表决器：a(b⊕c)+bc = ab+(a⊕b)c = c(a⊕b)+ab，全等价；P/G 思想：进位要么自己生成（G），要么从低位传递（P）

## 今日笔记
- 触发器的"族谱"：基本 RS → 锁存器（电平）→ 触发器（边沿）——越来越抗干扰
- 锁存器代码：`assign q = ena ? d : q;`（反馈式 mux）；触发器代码：`always @(posedge clk) q <= d;`
- 向量赋值 = 多个触发器并联共享时钟：写一行、铺一片
- HDLBits 高频词表：posedge/negedge 沿、synchronous/asynchronous 同步异步、active high/low 有效电平、enable 使能、byte enable 字节使能

## 今日错题
- `if(areset = 1'd1)` 单等号（应 == 或直接 if(areset)）——找了一晚上才发现的隐形杀手
- 异步复位漏写 `or posedge areset`——areset 变 1 要等下一个 clk 沿才清，异步变同步
- dff16e 用 `byteena == 1'd0` 判断（应逐位 byteena[0]/byteena[1]），且复位漏 else 包住使能
