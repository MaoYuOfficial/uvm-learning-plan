# Day9 UART loopback 波形（tb_uart_top）
onerror {resume}
log -r /*

add wave -divider "TB 顶层"
add wave /tb_uart_top/clk
add wave /tb_uart_top/rst_n
add wave /tb_uart_top/rxd
add wave /tb_uart_top/txd

add wave -divider "uart_rx（接收）"
add wave /tb_uart_top/utop_uart_top/in_uart_top/rx_state
add wave /tb_uart_top/utop_uart_top/in_uart_top/rx_cnt
add wave /tb_uart_top/utop_uart_top/in_uart_top/clk_cnt
add wave /tb_uart_top/utop_uart_top/in_uart_top/data
add wave /tb_uart_top/utop_uart_top/in_uart_top/done

add wave -divider "uart_loop（环回）"
add wave /tb_uart_top/utop_uart_top/mid_uart_loop/state
add wave /tb_uart_top/utop_uart_top/mid_uart_loop/rx_done_d0
add wave /tb_uart_top/utop_uart_top/mid_uart_loop/rx_done_d1
add wave /tb_uart_top/utop_uart_top/mid_uart_loop/rx_start_flag
add wave /tb_uart_top/utop_uart_top/mid_uart_loop/flash_data
add wave /tb_uart_top/utop_uart_top/mid_uart_loop/tx_req
add wave /tb_uart_top/utop_uart_top/mid_uart_loop/tx_data

add wave -divider "uart_tx（发送）"
add wave /tb_uart_top/utop_uart_top/out_uart_top/state
add wave /tb_uart_top/utop_uart_top/out_uart_top/shift
add wave /tb_uart_top/utop_uart_top/out_uart_top/cnt
add wave /tb_uart_top/utop_uart_top/out_uart_top/tx_busy
add wave /tb_uart_top/utop_uart_top/out_uart_top/baud_pulse

run 250us
wave zoom full
