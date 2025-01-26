@echo off

echo E80 GHDL synthesis script for the FPGA implementation

echo --------------------------------------------------------------
echo 1. Import and parse all VHDL files into the workspace :
echo    ghdl -i --std=08 ..\VHDL\*.vhd
ghdl -i --std=08 ..\VHDL\*.vhd
if %errorlevel% NEQ 0 pause
echo --------------------------------------------------------------
echo 2. Make the design with FPGA as top unit :
echo    ghdl -m --std=08 -Wno-hide FPGA
ghdl -m --std=08 -Wno-hide FPGA
if %errorlevel% NEQ 0 pause
echo --------------------------------------------------------------
echo 3. Synthesise the design into a single vhdl file:
echo    ghdl --synth --std=08 FPGA > FPGA.GHDL.vhdl
ghdl --synth --std=08 FPGA > FPGA.GHDL.vhdl
@if %errorlevel% NEQ 0 pause
echo --------------------------------------------------------------
echo Done. You can add FPGA.GHDL.vhdl into a project with
echo support.vhd and firmware.vhd