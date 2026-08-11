// uart_baud.v —— 波特率发生器（第 5 天）
// 规格：50 MHz 系统时钟 → 115200 波特率位时钟
// 原理：50_000_000 / 115200 = 434.03 → 数 0~433 共 434 个周期，每 434 周期出 1 个窄脉冲
// 实际波特率 50M/434 = 115207 bps，误差 ≈0.006% 达标
module uart_baud(
    input  clk,        // 50 MHz 系统时钟
    input  rst_n,      // 异步复位，低有效
    output baud_pulse  // 每 434 周期出 1 个时钟周期宽的高脉冲
);

localparam CNT_MAX = 433;
reg [9:0] cnt;
reg baud_pulse_r;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 10'd0;
        baud_pulse_r <= 1'd0;
    end
    else if(cnt == CNT_MAX)begin
        cnt <= 10'd0;
        baud_pulse_r <= 1'b1;
    end
    else begin
        cnt <= cnt + 1'b1;
        baud_pulse_r <= 1'b0;
    end
end

assign baud_pulse = baud_pulse_r;

// TODO: 你自己写（4 个自查点：复位值/位宽/边界动作/非阻塞赋值）

endmodule
