### Instructions for setting up the GateMateA1-EVB FPGA with the E80 Toolchain

1. Install the [latest version of the toolchain](https://github.com/Stokpan/E80/releases) and navigate to its folder.
2. Download the [OSS CAD Suite for Windows](https://github.com/YosysHQ/oss-cad-suite-build/releases) and run it on the toolchain folder; it will extract its oss-cad-suite folder there.
3. Connect the GateMate board to your computer via USB, locate the new DirtyJtag device on the Device Manager, and update it to the `Boards\Yosys_GateMateA1\Driver` subfolder. The device should now appear under Universal Serial Bus devices (not the standard USB adapters).
4. Open `Boards\Yosys_GateMateA1\E80.ccf` in a text editor and connect the components according to the Pin Assignments section.
   <br><img src="GateMateA1-EVB.jpg" width="1400" height="875">
   <br><img src="GateMateA1-EVBclose.jpg" width="1200" height="618">
   _The LED module requires a 5V VCC input at 330mA. For my testing purposes, I connected it to the 2.5V VDD pin #1 in BANK_NB1, but it's best to use a dedicated supply instead._
5. Run `Boards\Yosys_GateMateA1\synth.bat` and wait until all steps, from elaboration to flashing, are finished:
   <br><img alt="E80 VHDL Synthesis batch" src="synth.png" width="685" height="286">
6. The LED Matrix test will start running indefinitely.