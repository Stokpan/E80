# E80 Computer - Timing constraints for the Tang Primer 25K
# EDA: Gowin V1.9.11.01 Education
# FPGA: GW5A-25 Version A (GW5A-LV25MG121NC1/I0)

# 50 MHz FPGA clock
create_clock -name CLK50MHz [get_ports {CLK50MHz}] -period 20 -waveform {0 10}

# 100 Hz CPU deciHertz-class clock, tested for 1 kHz because Quartus refuses
# to accept a very low frequency clock
create_generated_clock -name CLK -source [get_ports {CLK50MHz}] [get_nets {CLK}] -divide_by 50000