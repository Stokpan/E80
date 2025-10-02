# E80 Computer - Timing Constraints for the DSD-i1
# Quartus Prime Version 20.1.1 Lite Edition
# Device Cyclone IV E (EP4CE6E22C8)

# 50 MHz FPGA clock
create_clock -name CLK50MHz [get_ports {CLK50MHz}] -period 20 -waveform {0 10}

# 1 kHz CPU clock (actually, upper limit is 100 Hz but some EDAs refuse to accept such a low limit)
create_generated_clock -name CLK -source [get_ports {CLK50MHz}] [get_nets {CLK}] -divide_by 50000

derive_clock_uncertainty