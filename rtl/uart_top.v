module uart_top(//头文件，接线
    input clk,
    input rst_n,
    input rxd,
    output txd
);

//模块间所需要的线
wire [7:0] rx_data;
wire rx_done;
wire tx_busy;
wire tx_flag;
wire [7:0] tx_data;

uart_rx in_uart_top(//输入模块接线
    .clk   (clk),
    .rst_n (rst_n),
    .rxd   (rxd),
    .data  (rx_data),
    .done  (rx_done)
);

uart_tx out_uart_top(//发送模块接线
    .clk        (clk),
    .rst_n      (rst_n),
    .tx_flag    (tx_flag),
    .tx_data    (tx_data),
    .tx_busy    (tx_busy), 
    .txd    (txd)  

);

uart_loop mid_uart_loop(//环回模块接线
    .clk       (clk),       
    .rst_n     (rst_n),       
    .rx_done   (rx_done),       
    .rx_data   (rx_data), 
    .tx_busy   (tx_busy),       
    .tx_req    (tx_flag),  
    .tx_data   (tx_data)
);

endmodule