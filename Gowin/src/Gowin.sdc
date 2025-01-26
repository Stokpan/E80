// E80 Computer - Timing Constraints for the Tang Primer 25K
// Gowin V1.9.11.01 Education (64-bit)
// FPGA: GW5A-25 Version A (GW5A-LV25MG121NC1/I0)

create_clock -name Clock50Mhz -period 20 -waveform {0 10} [get_ports {CLK50MHz}]