# E80 Computer - Timing constraints for the Hellenic Open University DSD-i1 - 2026.1.31
# EDA: Quartus Prime Version 20.1.1 Lite Edition
# FPGA: Cyclone IV E (EP4CE6E22C8)

# 50 MHz primary clock
create_clock -name BoardCLK [get_ports {BoardCLK}] -period 20

# Variable speed generated clock, up to 1 MHz
create_generated_clock -name CLK -source [get_ports {BoardCLK}] [get_nets {CLK}] -divide_by 50

derive_clock_uncertainty