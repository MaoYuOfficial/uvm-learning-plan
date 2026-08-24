`timescale 1ns/1ps

module tb_uart_baud;
    logic clk = 0;
    logic rst_n = 0;
    logic baud_pulse;


uart_baud u_uart_baud(
    .clk(clk),
    .rst_n(rst_n),
    .baud_pulse(baud_pulse)
);

always #10 clk = ~clk;

initial begin
    #100 rst_n = 1;
    #50000 $finish;
end

initial $monitor("t=%0t cnt=%0d baud_pulse+%b",$time,u_uart_baud.cnt,baud_pulse);

endmodule