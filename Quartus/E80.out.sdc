#######################################################################
## E80 Computer - Quartus Timing Constraints for the DSD-i1
## Device Cyclone IV E - "EP4CE6E22C8"
#######################################################################

set_time_format -unit ns -decimal_places 3
create_clock -name {CLK50MHz} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLK50MHz}]
create_clock -name {CLK} -period 1000000.000 -waveform { 0.000 500000.000 } [get_registers {CLK}]
set_clock_uncertainty -rise_from [get_clocks {CLK50MHz}] -rise_to [get_clocks {CLK50MHz}] -setup 1
set_clock_uncertainty -rise_from [get_clocks {CLK50MHz}] -rise_to [get_clocks {CLK50MHz}] -hold 0.020
set_clock_uncertainty -rise_from [get_clocks {CLK50MHz}] -fall_to [get_clocks {CLK50MHz}] -setup 1
set_clock_uncertainty -rise_from [get_clocks {CLK50MHz}] -fall_to [get_clocks {CLK50MHz}] -hold 0.020
set_clock_uncertainty -rise_from [get_clocks {CLK50MHz}] -rise_to [get_clocks {CLK}] 0.030
set_clock_uncertainty -rise_from [get_clocks {CLK50MHz}] -fall_to [get_clocks {CLK}] 0.030
set_clock_uncertainty -fall_from [get_clocks {CLK50MHz}] -rise_to [get_clocks {CLK50MHz}] -setup 1
set_clock_uncertainty -fall_from [get_clocks {CLK50MHz}] -rise_to [get_clocks {CLK50MHz}] -hold 0.020
set_clock_uncertainty -fall_from [get_clocks {CLK50MHz}] -fall_to [get_clocks {CLK50MHz}] -setup 1
set_clock_uncertainty -fall_from [get_clocks {CLK50MHz}] -fall_to [get_clocks {CLK50MHz}] -hold 0.020
set_clock_uncertainty -fall_from [get_clocks {CLK50MHz}] -rise_to [get_clocks {CLK}] 0.030
set_clock_uncertainty -fall_from [get_clocks {CLK50MHz}] -fall_to [get_clocks {CLK}] 0.030
set_clock_uncertainty -rise_from [get_clocks {CLK}] -rise_to [get_clocks {CLK50MHz}] 0.030
set_clock_uncertainty -rise_from [get_clocks {CLK}] -fall_to [get_clocks {CLK50MHz}] 0.030
set_clock_uncertainty -rise_from [get_clocks {CLK}] -rise_to [get_clocks {CLK}] 0.020
set_clock_uncertainty -rise_from [get_clocks {CLK}] -fall_to [get_clocks {CLK}] 0.020
set_clock_uncertainty -fall_from [get_clocks {CLK}] -rise_to [get_clocks {CLK50MHz}] 0.030
set_clock_uncertainty -fall_from [get_clocks {CLK}] -fall_to [get_clocks {CLK50MHz}] 0.030
set_clock_uncertainty -fall_from [get_clocks {CLK}] -rise_to [get_clocks {CLK}] 0.020
set_clock_uncertainty -fall_from [get_clocks {CLK}] -fall_to [get_clocks {CLK}] 0.020
set_input_delay -add_delay -clock [get_clocks {CLK}] 20.000 [get_ports {Reset}]
set_max_delay -from [get_clocks *] -through [get_pins -compatibility_mode *] -to [get_clocks *] 1000.000