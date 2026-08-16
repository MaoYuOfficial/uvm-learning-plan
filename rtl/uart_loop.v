module uart_loop(//环回模块
    input clk,              //时钟信号
    input rst_n,            //复位信号
    input rx_done,          //接收完成信号
    input [7:0] rx_data,    //接收的数据
    input tx_busy,          //发送器忙碌状态
    output reg tx_req,      //发送请求
    output reg [7:0] tx_data//输出的数据
);

reg rx_done_d0;//依旧打拍寄存器
reg rx_done_d1;
reg [1:0] state;//状态变量
reg [7:0] flash_data; //内容快照
wire rx_start_flag;//开始信号
localparam IDEL = 2'd0, SEND = 2'd1, WAIT_TX = 2'd2;//状态常量

assign rx_start_flag = ~rx_done_d1 & rx_done_d0;

always@(posedge clk or negedge rst_n)begin//抓取rx_done上升沿作为开始信号
    if(!rst_n)begin
        rx_done_d0 <= 1'd0;
        rx_done_d1 <= 1'd0;
    end

    else begin
        rx_done_d0 <= rx_done;
        rx_done_d1 <= rx_done_d0;
    end
end

always@(posedge clk or negedge rst_n)begin//状态判断
    if(!rst_n)begin
        state <= IDEL ;//复位回到初始状态
        flash_data <= 8'd0 ;//复位时清空快照
    end

    else if(rx_start_flag == 1'd1 && state == IDEL && tx_busy != 1'd1)begin//如果开始信号触发且发送器不忙，转换为发送状态并保存快照
        flash_data <= rx_data;
        state <= SEND;
    end

    else if(state == SEND && tx_busy == 1'd1)begin//如果发送完成，发送器已经启动，转为等待状态
        state <= WAIT_TX;
    end

    else if(state == WAIT_TX && tx_busy != 1'd1)begin//如果等待完发送器发送完毕，转为默认状态，清空快照
        flash_data <= 8'd0;
        state <= IDEL;

    end

    else;
end

always@(posedge clk or negedge rst_n)begin//状态输出
    if(!rst_n)begin//复位信号复位发送请求和清空输出数据
        tx_req <= 0;
        tx_data <= 8'd0;
    end
        
    else if(state == SEND)begin//发送状态发送快照数据并拉高发送请求
        tx_req <= 1'd1 ;
        tx_data <= flash_data;
    end

    else if(state == WAIT_TX)begin//等待状态复位完成信号
        tx_req <= 1'd0;
    end

    else if(state == IDEL)begin//默认状态复位
        tx_req <= 1'd0;
    end

    else;

end
        

endmodule