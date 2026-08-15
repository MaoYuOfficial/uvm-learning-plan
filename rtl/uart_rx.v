module uart_rx( //接收模块
    input clk,//时钟
    input rst_n,//复位信号
    input rxd,//输入信号
    output reg [7:0]data,//输出数据
    output reg done//完成信号
);

parameter CLK_FREQ = 50000000;//时钟周期常量
parameter UART_BPS = 115200;//波特率常量
localparam IDEL = 2'd0, START = 2'd1, R_DATA = 2'd2, STOP = 2'd3;//本地常量表示状态

//双寄存器打拍：检测 rxd 下降沿（顺带降低亚稳态概率）
reg rxd_d0;
reg rxd_d1;
reg [1:0]rx_state;//当前状态
reg [3:0]rx_cnt;//计数器
reg [12:0]clk_cnt;//计数器时钟
wire start_flag;//开始信号

assign start_flag = ~rxd_d0 & rxd_d1;//开始信号表示法

always@(posedge clk or negedge rst_n)begin//时序部分
    if(!rst_n)begin
    rxd_d0 <= 1'b0;
    rxd_d1 <= 1'b0;
    rx_state <= IDEL;
    end
    else begin//双寄存检测器
        rxd_d0 <= rxd;
        rxd_d1 <= rxd_d0;
    end

end

always@(posedge clk or negedge rst_n)begin//判断状态
    if(!rst_n)begin//复位信号
        rx_cnt <= 4'd0;//计数器复位
        clk_cnt <= 13'd0;//计数器时钟复位
    end

    else begin//clk上升沿时触发下列条件
        if(rx_state == IDEL)begin//默认状态接受开始信号
            if(start_flag)//如果开始信号为1，状态变为启动
            rx_state <= START;
            else
            rx_state <= IDEL;//兜底
        end

        else if (rx_state == START)//如果是启动状态，状态变为传输
            rx_state <= R_DATA;

        else if(rx_cnt == 4'd9 && clk_cnt == CLK_FREQ/UART_BPS - 1)begin//如果计数器走完了传输，状态变为停止
            rx_state <= STOP;
            clk_cnt <= 13'd0;
        end

        else if(rx_state == R_DATA)begin//传输时计数
            if(clk_cnt == CLK_FREQ/UART_BPS - 1)begin
                rx_cnt <= rx_cnt + 1;
                clk_cnt <= 13'd0;
            end
            else
            clk_cnt <= clk_cnt + 1;
        end

        else if(rx_state == STOP)begin//结束时复位
            rx_cnt <= 4'd0;
            rx_state <= IDEL;
        end

        else
        rx_state <= IDEL;//兜底
    end
end

always@(posedge clk or negedge rst_n)begin//传输部分
    if(!rst_n)begin//复位数据和完成信号
        done <= 1'd0;
        data <= 8'd0;
    end

    else if(rx_state == R_DATA && clk_cnt == CLK_FREQ/UART_BPS/2 && rx_cnt <= 8 && rx_cnt >= 1)//传输状态时，每当传输时钟计数到cnt中位时导入数据
        data[rx_cnt - 1] <= rxd_d1;

    else if(rx_state == STOP)//传完输出完成信号
        done <= 1'd1;

    else if(rx_state == IDEL)//空闲恢复完成信号
        done <= 1'd0;
    
    else;

end

endmodule
