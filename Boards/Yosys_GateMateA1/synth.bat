@echo off
echo -----------------------------------------------------------------------
echo This will synthesize the E80 VHDL code (incl. your program's firmware),
echo and then flash the output bitstream to the Olimex GateMateA1-EVB board.
echo -----------------------------------------------------------------------
REM Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

setlocal
cd %~dp0

set PATH=%~dp0..\..\oss-cad-suite\bin;%~dp0..\..\oss-cad-suite\lib;%~dp0..\..\GHDL\bin;%path%

echo 1. OSS CAD Suite check
nextpnr-himbaechel -V > NUL 2>&1
if %errorlevel% == 0 goto :detect_board
	cd ..\..
	echo Not found. Get the latest from github.com/YosysHQ/oss-cad-suite-build
	echo and extract it on the E80 Toolchain installation folder, so that
	echo "%cd%\oss-cad-suite" contains bin, lib, etc.
	echo Press any key to exit
	pause > nul
exit /b

:detect_board
echo 2. Board connection check
openfpgaloader -b olimex_gatemateevb --detect > NUL 2>&1
if %errorlevel% == 0 goto :start
	echo Board not found. If it's connected and PWR_LED1 is on, check for
	echo a dirtyJtag device under "Universal Serial Bus devices". If it's
	echo on "Other devices", install the driver from the "Driver" folder.
	echo If the driver is installed, try pressing FPGA_RST1.

:start
cd %~dp0
rd /s /q TempOutput > nul 2>&1
md TempOutput > nul 2>&1
cd TempOutput

echo 3. Elaboration (ghdl)
set log=ghdl.log
copy NUL %log% > NUL
set command=ghdl -i --std=08 ..\..\..\VHDL\*.vhd ..\Board.vhd
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
set command=ghdl -m --std=08 -Wno-hide Interface
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
set command=ghdl --synth --std=08 --out=verilog Interface
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% > Interface.v 2>>%log%
if %errorlevel% NEQ 0 goto :error

echo 4. Synthesis (yosys) -- slow
set log=yosys.log
copy NUL %log% > NUL
set command=yosys -p "read_verilog Interface.v; synth_gatemate -top Interface -luttree -nomx8 -nomult; write_json Interface.json"
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

echo 5. Place and Route (nextpnr) -- SLOW!
set log=nextpnr.log
copy NUL %log% > NUL
set command=nextpnr-himbaechel --device CCGM1A1 --json Interface.json -o ccf=..\E80.ccf -o out=Interface.impl --router router2 --ignore-loops --freq 2 --timing-allow-fail
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

echo 6. Bitstream Packing (gmpack)
set log=gmpack.log
copy NUL %log% > NUL
set command=gmpack Interface.impl Interface.bit -v
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

echo 7. FPGA Flashing (openfpgaloader)
set log=openfpgaloader.log
copy NUL %log% > NUL
set command=..\openfpgaloader -c dirtyJtag Interface.bit
:openfpgaloader
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel%==0 (
	echo Done.
) else (
	echo Failed! Try pressing the FPGA_RST1 button.
)
echo Hit [3] to restart synthesis, [Esc] to exit, or any other key to reflash.
REM clear keyboard buffer and read Esc key via powershell
for /f %%k in ('powershell -Command "while([Console]::KeyAvailable){[void][Console]::ReadKey($true)}; $k=[Console]::ReadKey($true); if($k.KeyChar -eq '3'){1}elseif($k.Key -eq 'Escape'){2}"') do (
	if %%k==1 goto :start
	if %%k==2 exit /b
)
goto :openfpgaloader

:error
echo Failed! Available changelogs:
dir /b *.log
pause
explorer .