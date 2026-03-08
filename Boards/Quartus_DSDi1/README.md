
1. Install [Quartus Prime Lite](https://www.altera.com/downloads/fpga-development-tools/quartus-prime-lite-edition-design-software-version-20-1-1-windows) and the DSD-i1 driver and X2Loader according to the Hellenic Open University's DSMC Lab instructions.
2. Open E80.qsf in a text editor and connect the components according to the Pin Assignments section and these images: <img src="DSD-i1.jpg" width="1400" height="783" /> <img src="DSD-i1%20close.jpg" width="1200" height="662" />
3. Open the E80.qpf project file in Quartus.
4. Hit Ctrl-L to start compilation.
5. When the compilation is finished start X2Loader. Check out the available COM ports. Connect the board, then close and reopen X2Loader. Notice there's a new COM port. Select this one, click Connect, and then Upload Bitstream. Select the RBF file from the output_files folder.
6. The LED Matrix test will start running.