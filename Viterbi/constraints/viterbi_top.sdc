# 200 MHz target. Set I/O delays, loads and driving cells for the actual platform.
create_clock -name core_clk -period 5.000 [get_ports clk]
