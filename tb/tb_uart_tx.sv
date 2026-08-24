`timescale 1ns/1ps//设定时钟周期

module tb_uart_tx;//testbench端口
    logic clk = 0;
    logic rst_n = 0;
    logic tx_flag = 0;
    logic [7:0]tx_data;
    logic txd;

uart_tx utx_uart_tx(//例化链接uart_tx
    .clk(clk),
    .rst_n(rst_n),
    .tx_flag(tx_flag),
    .tx_data(tx_data),
    .txd(txd)
);

always #10 clk = ~clk;//clk每10个周期震荡一次

initial begin//默认开始时
    #100 rst_n = 1;//rst_n在一段时间后复位
    tx_data = 8'b01010101;//设定要上传的数据
    tx_flag = 1;//拉高表示开始传送
    #17360 tx_flag = 0;//开始信号一段时间后复位
    #200000 $finish;//走完一帧多后结束模拟
end

endmodule

