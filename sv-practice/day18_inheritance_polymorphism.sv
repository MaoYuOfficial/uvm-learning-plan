class uart_transaction;//父类
    bit [7:0] data;
    bit parity_err;
    int baud_div;

    function new(bit [7:0]d, int b_div);
        data = d;
        parity_err = 0;
        baud_div = b_div;
        
    endfunction

    virtual function void display();
        $display("Normal transaction: data = %0b parity_err = %0b baud_div = %0d",data ,parity_err ,baud_div );

    endfunction
endclass

class error_transaction extends uart_transaction;//子类
    bit force_error;

    function new(bit [7:0]d, int b_div);
        super.new(d, b_div);

        force_error = 1;
        parity_err  = 1;
        
    endfunction

    virtual function void display();
        $display("Error transaction: data = %0b parity_err = %0b baud_div = %0d force_error = %0b",data ,parity_err ,baud_div ,force_error);

    endfunction

endclass

module tb_day18;//验证子类数据可以被指向父类
    
    uart_transaction    normal_tr;
    error_transaction   err_tr;

    uart_transaction    tr;

    initial begin
        normal_tr = new(8'h55, 434);
        tr = normal_tr;
        tr.display();

        err_tr = new(8'hAA, 434);
        tr = err_tr;
        tr.display();

        $finish;
    end
    
endmodule