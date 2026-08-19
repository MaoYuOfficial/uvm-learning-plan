module uart_top(//头文件，接线
    input clk,
    input rst_n,//外部原始复位（可能异步释放，先进复位同步器）
    input rxd,
    output txd
);

wire rst_n_sync;//复位同步器输出，内部所有模块都用这个复位

//模块间所需要的线
wire [7:0] rx_data;
wire rx_done;
wire tx_busy;
wire tx_flag;
wire [7:0] tx_data;

rst_sync u_rst_sync(//复位同步器：rst_n 异步拉低立即复位，释放同步到时钟沿
    .clk        (clk),
    .rst_n      (rst_n),
    .rst_n_sync (rst_n_sync)
);

uart_rx in_uart_top(//输入模块接线
    .clk   (clk),
    .rst_n (rst_n_sync),
    .rxd   (rxd),
    .data  (rx_data),
    .done  (rx_done)
);

uart_tx out_uart_top(//发送模块接线
    .clk        (clk),
    .rst_n      (rst_n_sync),
    .tx_flag    (tx_flag),
    .tx_data    (tx_data),
    .tx_busy    (tx_busy), 
    .txd    (txd)  

);

uart_loop mid_uart_loop(//环回模块接线
    .clk       (clk),       
    .rst_n     (rst_n_sync),       
    .rx_done   (rx_done),       
    .rx_data   (rx_data), 
    .tx_busy   (tx_busy),       
    .tx_req    (tx_flag),  
    .tx_data   (tx_data)
);

endmodule