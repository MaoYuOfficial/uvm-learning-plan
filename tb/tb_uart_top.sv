`timescale 1ns/1ps//设定时钟周期

class uart_transaction;
    logic [7:0] data;
    bit parity_err;
    int baud_div;

    function new(logic [7:0] d, int bd);
        data  = d;
        baud_div = bd;
        parity_err = 0;
    endfunction


    function void display();
        $display("data = %b , baud_div = %d , parity_err = %b", data, baud_div, parity_err);

    endfunction

endclass

module tb_uart_top;//testbench端口
    logic clk = 0;
    logic rst_n = 0;
    logic rxd = 1;
    logic txd;

    uart_transaction txn;
    integer pass_cnt = 0;   //通过计数
    integer err_cnt = 0;    //未通过计数

uart_top utop_uart_top(//例化接线uart_top
    .clk    (clk),
    .rst_n  (rst_n),
    .rxd    (rxd),
    .txd    (txd)
);

always #10 clk = ~clk;//时钟信号

task send_byte(input [7:0] d);//发一帧：把 d 的 8 位按 LSB 在前依次摆到 rxd 上，每 bit 8680ns
    begin
    rxd = 0; #8680;
    rxd = d[0]; #8680;
    rxd = d[1]; #8680;
    rxd = d[2]; #8680;
    rxd = d[3]; #8680;
    rxd = d[4]; #8680;
    rxd = d[5]; #8680;
    rxd = d[6]; #8680;
    rxd = d[7]; #8680;
    rxd = 1; #8680;
    end
endtask

initial begin//主激励：发 3 帧、每帧收完自动比对、最后出总结
    #100 rst_n = 1;
    #100 txn = new(8'h55, 434);//令期望的数据为8'h55
    txn.display();
    send_byte(8'h55);//调用 task 发一帧 0x55
    @(posedge utop_uart_top.rx_done);//等 RX 收完本帧（收卷时机），再读 rx_data 比对
    if (utop_uart_top.rx_data == txn.data) begin//相同 → 报 PASS 并计数
        $display("PASS: exp 0x%02x == got 0x%02x", txn.data, utop_uart_top.rx_data);
        pass_cnt = pass_cnt + 1;
    end

    else begin//不同 → 报 FAIL 并计数
        $display("FAIL: exp 0x%02x != got 0x%02x", txn.data, utop_uart_top.rx_data);
        err_cnt = err_cnt + 1 ;
    end

    @(posedge utop_uart_top.tx_busy);//等回显开始（tx_busy 0→1）
    @(negedge utop_uart_top.tx_busy);//等回显发完（tx_busy 1→0），之后发下一帧才安全

    txn = new(8'hAA, 434);//第二帧数据传输，令期望的数据为8'hAA
    txn.display();
    send_byte(8'hAA);//调用 task 发一帧 0xAA
    @(posedge utop_uart_top.rx_done);//等 RX 收完本帧（收卷时机），再读 rx_data 比对
    if (utop_uart_top.rx_data == txn.data) begin//相同 → 报 PASS 并计数
        $display("PASS: exp 0x%02x == got 0x%02x", txn.data, utop_uart_top.rx_data);
        pass_cnt = pass_cnt + 1;
    end

    else begin//不同 → 报 FAIL 并计数
        $display("FAIL: exp 0x%02x != got 0x%02x", txn.data, utop_uart_top.rx_data);
        err_cnt = err_cnt + 1 ;
    end

    @(posedge utop_uart_top.tx_busy);//等回显开始（tx_busy 0→1）
    @(negedge utop_uart_top.tx_busy);//等回显发完（tx_busy 1→0），之后发下一帧才安全

    txn = new(8'h3C, 434);//第三帧同理
    txn.display();
    send_byte(8'h3C);
    @(posedge utop_uart_top.rx_done);
    if (utop_uart_top.rx_data == txn.data) begin
        $display("PASS: exp 0x%02x == got 0x%02x", txn.data, utop_uart_top.rx_data);
        pass_cnt = pass_cnt + 1;
    end

    else begin
        $display("FAIL: exp 0x%02x != got 0x%02x", txn.data, utop_uart_top.rx_data);
        err_cnt = err_cnt + 1 ;
    end

    @(posedge utop_uart_top.tx_busy);
    @(negedge utop_uart_top.tx_busy);

    $display ("--- 总结：共 3 帧，PASS %0d, FAIL %0d ---", pass_cnt, err_cnt);//输出对比结果
    $finish;
end

endmodule