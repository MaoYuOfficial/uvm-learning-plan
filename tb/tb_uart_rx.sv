`timescale 1ns/1ps//设定时钟周期

module tb_uart_rx;//testbench端口
    logic clk = 0;
    logic rst_n = 0;
    logic [7:0]data;
    logic done;
    logic rxd = 1;

uart_rx urx_uart_rx(//例化uart_rx
    .clk(clk),
    .rst_n(rst_n),
    .data(data),
    .rxd(rxd),
    .done(done)
);

always #10 clk = ~clk;//时钟信号


initial begin//rxd每一位输出一次信息给data
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

initial $monitor($time, " rxd=%b rx_state=%d rx_cnt=%d data=%h done=%b",
                 rxd, urx_uart_rx.rx_state, urx_uart_rx.rx_cnt, data, done);

endmodule
