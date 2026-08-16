// uart_tx.v —— UART 发送模块（第 6 天）
// 思路：单时序块 + baud_pulse 使能；shift 打包 tx_data；cnt 计数；
//       DATA 状态 txd = shift[cnt]（计数器索引方案，LSB 在前）
module uart_tx(
    input clk,          //时钟
    input rst_n,        //复位
    input tx_flag,      //开始信号
    input [7:0]tx_data, //要发送的数据
    output tx_busy,     //忙碌状态
    output reg txd      //1位输出
);

localparam IDEL = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;//状态常量

wire baud_pulse;//脉冲信号
reg [7:0]shift;//打包缓冲
reg [1:0]state;//状态
reg [3:0]cnt;//计数器

uart_baud utx_uart_baud(//接另外一个模型
    .clk(clk),
    .rst_n(rst_n),
    .baud_pulse(baud_pulse)
);

assign tx_busy = (state != IDEL);//该发送模块不在空闲状态时忙碌

// ============ 时序块：脉冲来时执行一次 ============
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= IDEL;
        cnt   <= 4'd0;
        shift <= 8'd0;             // 顺手把缓冲也复位
    end
    else if(baud_pulse)begin       // ← 一个脉冲只触发一次，无竞争
        if(state == IDEL && tx_flag)begin
            state <= START;        // 有请求才出发
        end
        else if(state == START)begin
            state <= DATA;         // 起始位待满 1 拍，进数据
            shift <= tx_data;      // 打包
        end
        else if(state == DATA)begin
            if(cnt == 4'd7)begin   // ← case 展开等价写法（更短）
                state <= STOP;     // 数到 7 跳停止
                cnt   <= 4'd0;
            end
            else
                cnt <= cnt + 1'b1; // 否则 +1
        end
        else if(state == STOP)begin
            state <= IDEL;         // 停止位完事回家
            cnt   <= 4'd0;
        end
        else
            state <= IDEL;         // 兜底
    end
end

// ============ 输出块：组合逻辑，txd = shift[cnt] ============
always@(*)begin
    case(state)
    IDEL:  txd = 1'b1;            // 空闲高
    START: txd = 1'b0;            // 起始低
    DATA:  txd = shift[cnt];      // ← 计数器索引方案
    STOP:  txd = 1'b1;           // 停止高
    default: txd = 1'b1;
    endcase
end

endmodule
