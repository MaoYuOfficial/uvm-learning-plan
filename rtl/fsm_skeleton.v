// fsm_skeleton.v —— 三段式 FSM 标准骨架模板（第 4 天完成标志·对照版）
// 用法：复制本文件，把状态名、转移条件、输出改成自己的
module fsm_skeleton (
    input  clk,          // 时钟
    input  res,          // 复位（高有效·异步）
    input  in,           // 输入
    output reg out       // 输出（在 always 里赋值必须 reg）
);

    // ① 状态编码（两两唯一，一个状态一个号）
    localparam A = 1'b0, B = 1'b1;
    reg state, next_state;              // 现态 + 次态

    // ② 时序段：状态寄存器（异步复位在敏感列表加 or，复位分支最前）
    always @(posedge clk or posedge res) begin
        if (res)      state <= A;       // 复位到默认状态
        else          state <= next_state;
    end

    // ③ 组合段：算次态（用 =；next_state = state 打底防锁存器；case 必配 default）
    always @(*) begin
        next_state = state;             // 默认保持
        case (state)
            A: if (in) next_state = B;  // ← 按你的状态图填转移条件
            B: if (~in) next_state = A; // ← 按你的状态图填转移条件
            default: next_state = A;    // 兜底非法状态
        endcase
    end

    // ④ 输出段：Moore 查 state；简单组合也可用 assign
    always @(*) begin
        case (state)
            B: out = 1'b1;              // ← 按你的状态图填输出
            default: out = 1'b0;
        endcase
    end

endmodule
