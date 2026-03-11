### Instructions for setting up the HOU DSD-i1 FPGA with the E80 Toolchain

The following assume that you have installed the [latest version of the toolchain](https://github.com/Stokpan/E80/releases).

1. Install [Quartus Prime Lite](https://www.altera.com/downloads/fpga-development-tools/quartus-prime-lite-edition-design-software-version-20-1-1-windows) and the DSD-i1 driver and X2Loader according to the Hellenic Open University's DSMC Lab instructions.
2. Open E80.qsf in a text editor and connect the components according to the Pin Assignments section.
   <img src="DSD-i1.jpg" width="1400" height="783" />
   <img src="DSD-i1%20close.jpg" width="1200" height="662" />
   _The LED module requires a 5V VCC input at 330mA. For my testing purposes, I connected it to the 3.3V VDD pin #37 in the HD2 bank for several hours without issues aside from lower brightness._
3. Open the E80.qpf project file in Quartus.
4. Hit Ctrl-L to start compilation.
5. When the compilation is finished start X2Loader. Check out the available COM ports. Connect the board, then close and reopen X2Loader. Notice there's a new COM port. Select this one, click Connect, and then Upload Bitstream. Select the RBF file from the output_files folder.
6. The LED Matrix test will start running indefinitely.