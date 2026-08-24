module data_types;

typedef struct {// 定义数据类型，struct是打包类型
    logic [7:0] data;
    logic parity_err;
} uart_frame_t;

typedef enum  { //定义数据类型，enum是枚举类型
    IDLE,
    START, 
    DATA, 
    STOP
} tx_state_t;


initial begin

logic [7:0] exp_arr [3];// 定宽数组
int baud_div[];//动态数组
logic [7:0] rx_q[$];// 队列数组
int baud_table[string];// 关联数组
string key;//关联数组的中间变量
uart_frame_t frame;//调用刚才定义的struct类型变量并取名
tx_state_t state;//调用刚才定义的enum类型变量并取名

exp_arr[0] = 8'h55;//直接赋值给定宽数组
exp_arr[1] = 8'haa;
exp_arr[2] = 8'h3c;

for (int i = 0; i < $size(exp_arr); i++) begin
    $display("exp_arr[%0d] = 0x%h", i, exp_arr[i]);
    
end

baud_div = new[3];//给动态数组定宽度
baud_div[0] = 5208;
baud_div[1] = 2604;
baud_div[2] = 434;

for(int j = 0; j < $size(baud_div); j++) begin
    $display("baud_div[%0d] = %d", j, baud_div[j]);

end

rx_q.push_back(8'h01);//调用push_back方法，让数据进入队列数组
rx_q.push_back(8'h02);
rx_q.push_back(8'h03);

$display("queue size after push = %0d", rx_q.size());

while (rx_q.size() > 0) begin//调用pop_front方法，让已存数据逐项清空
    $display("pop: 0x%02h", rx_q[0]);
    rx_q.pop_front();

end

baud_table["9600"] = 5208;//让关联数组的标签关联数据
baud_table["19200"] = 2604;
baud_table["115200"] = 434;

$display("table has %0d entries:", $size(baud_table));

if(baud_table.first(key)) begin
    do begin
        $display(" %s -> %d", key, baud_table[key]);

    end while (baud_table.next(key));

end

if(baud_table.exists("4800")) begin
    $display("check \"4800\": found, div = %0d", baud_table["4800"]);
end
else begin
    $display("check \"4800\": not found");
end

$display("check \"115200\": found, div = %0d", baud_table["115200"]);
$display("check \"19200\": found, div = %0d", baud_table["19200"]);
$display("check \"9600\": found, div = %0d", baud_table["9600"]);

frame.data =8'h55;//给定义后的frame内部赋值
frame.parity_err = 1;
$display("frame.data = 0x%02h", frame.data);
$display("frame.parity_err = %0d", frame.parity_err);

state = IDLE;//给定义的state分配状态结果
$display("state: %s", state.name());
state = START;
$display("state: %s", state.name());
state = DATA;
$display("state: %s", state.name());
state = STOP;
$display("state: %s", state.name());

$finish;

end

endmodule