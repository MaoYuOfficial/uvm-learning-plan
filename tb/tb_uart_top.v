`timescale 1ns/1ps//设定时钟周期

module tb_uart_top;//testbench端口
    reg clk = 0;
    reg rst_n = 0;
    reg rxd = 1;
    wire txd;

uart_top utop_uart_top(//例化接线uart_top
    .clk    (clk),
    .rst_n  (rst_n),
    .rxd    (rxd),
    .txd    (txd)
);

always #10 clk = ~clk;//时钟信号

initial begin//模拟rxd数据发送
    #100 rst_n = 1;
    #8680 rxd = 0;
    #8680 rxd = 1;
    #8680 rxd = 0;
    #8680 rxd = 1;
    #8680 rxd = 0;
    #8680 rxd = 1;
    #8680 rxd = 0;
    #8680 rxd = 1;
    #8680 rxd = 0;
    #8680 rxd = 1;
    #200000 $finish;
end

always @(posedge utop_uart_top.rx_done) begin //每当uart_rx部分完成一次发送就记录发送的数据
    $display("收到字节: 0x%02x", utop_uart_top.rx_data);
end

initial $monitor("t=%t rxd=%b, txd=%b ",$time ,rxd ,txd);//显示输入和输出数据关系

endmodule