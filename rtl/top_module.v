// HDLBits fsm1 提交版（module 名必须 top_module；本地仿真请用 fsm1.v + tb_fsm1.v）
// 三段式状态机：异步复位到 B / in=0 翻转 / in=1 保持
module top_module(
    input clk,
    input areset,
    input in,
    output reg out
);

//确定状态变量
localparam Sa = 1'b0, Sb = 1'b1;
reg stage, next_stage;

//时序
always @(posedge clk or posedge areset)begin
    if(areset)
    stage <= Sb;
    else
    stage <= next_stage;
end

//状态跳转
always@(*)begin
    next_stage = stage; //默认状态防止锁存
    case(stage)
    Sb: if(~in) next_stage = Sa;
    Sa: if(~in) next_stage = Sb;
    default: next_stage = Sb;
    endcase
end

//输出表示
always@(*)begin
    out = stage;
end
endmodule
