// day 1: ModelSim hello world
// 用法: vlib work; vlog hello.sv; vsim -c -do "run -all" work.hello
module hello;
  initial begin
    $display("hello, uvm-learning-plan day 1");
    $finish;
  end
endmodule
