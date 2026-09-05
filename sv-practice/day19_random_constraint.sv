//随机赋值以及限制随机范围

class uart_random_transaction;
    rand bit [7:0] data;
    randc int frame_pos;
    rand bit parity_err;
    rand int baud_div;

    constraint data_limit {
        $countones(data) >= 2;
        frame_pos >= 0;
        frame_pos <= 9;
        (frame_pos == 0) -> (parity_err == 1);
        (frame_pos != 0) -> (parity_err == 0);
        baud_div inside {434, 217, 109};
    };

endclass

module tb_day19;
    uart_random_transaction tr;

    initial begin
        tr = new();

        repeat (20) begin

            if(tr.randomize() == 0)begin
                $display("Randomization Failed");

            end

            else begin
                $display("data = %h, frame_pos = %0d, baud_div = %0d, parity_err = %0b", tr.data , tr.frame_pos , tr.baud_div , tr.parity_err);

            end

        end

        $finish;
    end

endmodule
