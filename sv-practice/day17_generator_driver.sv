class uart_transaction;
    bit [7:0] data;
    bit parity_err;
    int baud_div;

    function new(bit [7:0]d, int b_div);
        data = d;
        parity_err = 0;
        baud_div = b_div;

    endfunction
endclass

class uart_generator;
    uart_transaction queue[$];
    uart_transaction t;

    task generate_transactions();
        t = new(8'h55, 434);
        queue.push_back(t);
        t = new(8'hAA, 434);
        queue.push_back(t);
        t = new(8'h3C, 434);
        queue.push_back(t);

    endtask

endclass

class uart_driver;
    task drive(ref uart_transaction queue[$]);
        uart_transaction t;

        while (queue.size() != 0)begin
            t = queue.pop_front();
            #10;
            $display("Driver: drive data=%h", t.data);

        end

        $display("Queue is empty");

    endtask

endclass

module tb_day17;

    uart_generator  gen;
    uart_driver     drv;

    initial begin
        gen = new();
        drv = new();

        gen.generate_transactions();
        drv.drive(gen.queue);
        $display("Final queue size = %0d", gen.queue.size());
        
        $finish;

    end
    
endmodule