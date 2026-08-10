`timescale 1ns/1ps
// tb_fsm1.v —— fsm1 的测试台（第 4 天练习）
// 用法：ModelSim 里先编译 fsm1.v 再编译本文件，然后仿真 tb_fsm1
module tb_fsm1;

    reg  clk    = 0;
    reg  areset = 0;   // 注意：从 0 开始，等会儿拉高才有 0→1 跳变触发 posedge
    reg  in     = 0;
    wire out;

    // 例化被测模块（端口名和 fsm1.v 一一对应）
    fsm1 u_fsm1 (
        .clk    (clk),
        .areset (areset),
        .in     (in),
        .out    (out)
    );

    // 时钟发生器：周期 10ns（#5 翻转一次），上升沿在 5,15,25,35...
    always #5 clk = ~clk;

    // 复位 + 激励序列
    initial begin
        #5  areset = 1;    // 0→1 上升沿：异步复位触发，stage <= B，out=1
        #15 areset = 0;    // t=20 释放复位
        #10 in = 0;        // t=30 置 in=0 → 下一个沿 B→A，out 变 0
        #10 in = 1;        // t=40 置 in=1 → 保持 A，out 保持 0
        #10 in = 0;        // t=50 置 in=0 → 下一个沿 A→B，out 变 1
        #20 $finish;       // t=70 结束
    end

    // 打印状态变化（随便哪个信号变就打印一行）
    initial $monitor("t=%0t  areset=%b  in=%b  out=%b", $time, areset, in, out);

endmodule
