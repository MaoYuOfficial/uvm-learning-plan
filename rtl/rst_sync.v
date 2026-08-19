module rst_sync(//我是一个复位同步器，异步复位，同步释放
    input   clk,
    input   rst_n,
    output  rst_n_sync
);

reg d0,d1;//打拍变量

always@(posedge clk or negedge rst_n)
    if(!rst_n)begin//复位信号直接异步触发复位
        d0 <= 0;
        d1 <= 0;
    end

    else begin//clk上升沿打拍，同步释放信号
        d0 <= rst_n;
        d1 <= d0;
    end

assign rst_n_sync = d1;//后续复位信号连接当前打拍器

endmodule