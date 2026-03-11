### Instructions for setting up the Tang Primer 25K FPGA with the E80 Toolchain

The following assume that you have installed the [latest version of the toolchain](https://github.com/Stokpan/E80/releases).

1. Install Gowin EDA Student Edition ([Windows](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_x64_win.zip), [Linux](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_Linux.tar.gz), [MacOS](https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03Education_macOS.dmg)).
2. Open E80.cst in a text editor and connect the components according to the Pin Assignments section.
   <img src="Tang%20Primer%2025K.jpg" width="1400" height="702" />
   <img src="Tang%20Primer%2025K%20close.jpg" width="1200" height="458" />
   _Pin #11 of the top 2x20 vertical header provides 5V output, matching the requirements of the 4x8x8 LED module._
3. Open the Gowin.gprj project file in Gowin.
4. Compile the project using Run All and connect your Tang Primer 25K board to your PC.
5. When the compilation is finished use the Programmer function (click on USB Cable Setting > Save, and then click on Program/Configure) to upload the bitstream. I sometimes need to click multiple times on Program/Configure.
6. The LED Matrix test will start running indefinitely.