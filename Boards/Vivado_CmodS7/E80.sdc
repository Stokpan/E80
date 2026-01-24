# E80 Computer - Timing constraints for the Digilent Cmod S7 - 2026.2.3
# EDA: Vivado 2025.1 Standard Edition
# FPGA: Spartan-7 (xc7s25csga225-1 / XC7S25-1CSGA225C)

# 12 MHz primary clock
create_clock -name BoardCLK [get_ports {BoardCLK}] -period 82

# Variable speed generated clock, up to 1 MHz
create_generated_clock -name CLK -source [get_ports {BoardCLK}] [get_nets {CLK}] -divide_by 12