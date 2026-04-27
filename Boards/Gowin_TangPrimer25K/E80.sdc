# E80 Computer - Timing constraints for the Sipeed Tang Primer 25K - 2026.4.27
# EDA: Gowin V1.9.11.03 Education
# FPGA: GW5A-25 Version A (GW5A-LV25MG121NC1/I0)

# 50 MHz primary clock
create_clock -name BoardCLK [get_ports {BoardCLK}] -period 20

# All generated clocks are ≤ 2 Mhz

# CPU clock
create_generated_clock -name CPU_CLK -source [get_ports {BoardCLK}] [get_nets {CLK}] -divide_by 25

# Control buttons and LED display process clock
create_generated_clock -name Interface_CLK1MHz -source [get_ports {BoardCLK}] [get_nets {GenCLK[7]}] -divide_by 25