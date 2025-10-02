# E80 Computer - Timing Constraints for the Tang Primer 25K
# Gowin V1.9.11.01 Education
# Device GW5A-25 Version A (GW5A-LV25MG121NC1/I0)

# 50 MHz FPGA clock
create_clock -name CLK50MHz [get_ports {CLK50MHz}] -period 20 -waveform {0 10}

# 1 kHz CPU clock (actually, upper limit is 100 Hz but some EDAs refuse to accept such a low limit)
create_generated_clock -name CLK -source [get_ports {CLK50MHz}] [get_nets {CLK}] -divide_by 50000