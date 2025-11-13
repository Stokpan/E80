# E80 Computer - Timing constraints for the DSD-i1
# EDA: Quartus Prime Version 20.1.1 Lite Edition
# FPGA: Cyclone IV E (EP4CE6E22C8)

# 50 MHz FPGA clock
create_clock -name CLK50MHz [get_ports {CLK50MHz}] -period 20

# 100 Hz CPU deciHertz-class clock, constrained to 1 KHz to match the minimum
# frequency floor used for timing analysis in Quartus
create_generated_clock -name CLK -source [get_ports {CLK50MHz}] [get_nets {CLK}] -divide_by 50000

derive_clock_uncertainty