@echo off
cd /d D:\uvm-learning-plan
start "ModelSim Day9" "D:\ModelSim\win64\vsim.exe" -gui work.tb_uart_top -voptargs=+acc -do "do sim/day9_wave.do"
