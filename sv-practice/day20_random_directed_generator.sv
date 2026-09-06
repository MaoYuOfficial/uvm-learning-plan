//综合应用

class uart_random_transaction;
    rand bit [7:0] data;
    randc int frame_pos;
    rand bit parity_err;
    rand int baud_div;

    function new(bit [7:0]d, int fp, bit pe, int bd);
        data = d;
        frame_pos = fp;
        parity_err = pe;
        baud_div = bd;
    
    endfunction

    constraint data_limit {
        $countones(data) >= 2;
        frame_pos >= 0;
        frame_pos <= 9;
        (frame_pos == 0) -> (parity_err == 1);
        (frame_pos != 0) -> (parity_err == 0);
        baud_div inside {434, 217, 109};
    };

endclass

class uart_generator;
    uart_random_transaction queue[$];
    uart_random_transaction t;

    task generate_transactions();
        t = new(8'h00, 1, 0, 434);
        queue.push_back(t);
        t = new(8'hff, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h55, 1, 0, 434);
        queue.push_back(t);
        t = new(8'haa, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h01, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h02, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h04, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h08, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h10, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h20, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h40, 1, 0, 434);
        queue.push_back(t);
        t = new(8'h80, 1, 0, 434);
        queue.push_back(t);

        repeat (5) begin
            
            t = new(8'h00, 1, 0, 434);
            if(t.randomize() == 0)begin
                $display("Randomization Failed");
            end
            else begin
                queue.push_back(t);
            end

        end

    endtask

endclass

class uart_driver;
    task drive(ref uart_random_transaction queue[$]);
        uart_random_transaction t;

        while (queue.size() != 0)begin
            t = queue.pop_front();
            #10;
            $display("Driver: drive data = %0h frame_pos = %0d parity_err = %0b baud_div = %0d", t.data, t.frame_pos, t.parity_err, t.baud_div);

        end

        $display("Queue is empty");

    endtask

endclass

module tb_day20;
    uart_generator  tg;
    uart_driver     td;

    initial begin
        tg = new();
        td = new();

        tg.generate_transactions();
        td.drive(tg.queue);
        $display("Final queue size = %0d", tg.queue.size());

        $finish;
    end

endmodule