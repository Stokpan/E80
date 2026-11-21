# E80 Computer - Timing constraints for the generic Cyclone IV EP4CE6E22 board - 2026.11.22
# EDA: Quartus Prime Version 20.1.1 Lite Edition
# FPGA: Cyclone IV E (EP4CE6E22C8)

# 50 MHz primary clock
create_clock -name BoardCLK [get_ports {BoardCLK}] -period 20

# All generated clocks are ≤ 2 MHz

# CPU clock
create_clock -name CLK -period 500 [get_nets {CLK}]

# Control buttons and LED display process clock
create_clock -name Interface_CLK1MHz -period 500 [get_nets {ClockGen:ClockGen_inst|Count500ns[1]}]

# Let Quartus automatically apply uncertainty assignments
derive_clock_uncertainty