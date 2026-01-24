# E80 Computer - Timing constraints for the Sipeed Tang Primer 25K - 2026.1.31
# EDA: Gowin V1.9.11.03 Education
# FPGA: GW5A-25 Version A (GW5A-LV25MG121NC1/I0)

# 50 MHz primary clock
create_clock -name BoardCLK [get_ports {BoardCLK}] -period 20

# Variable speed generated clock, up to 1 MHz
create_generated_clock -name CLK -source [get_ports {BoardCLK}] [get_nets {CLK}] -divide_by 50