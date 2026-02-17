@echo off
title E80 VHDL Synthesis batch
echo -----------------------------------------------------------------------
echo This will synthesize the E80 VHDL code (incl. your program's firmware),
echo and then flash the output bitstream to the Olimex GateMateA1-EVB board.
echo -----------------------------------------------------------------------
REM Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

setlocal
set PATH=%~dp0..\..\oss-cad-suite\bin;%~dp0..\..\oss-cad-suite\lib;%~dp0..\..\GHDL\bin;%path%
set TempOutput=%~dp0TempOutput
set bitstream=Interface.bit
REM To get the toolchain installation folder we must cd to it.
cd %~dp0..\..
set ToolchainFolder=%cd%

REM move to work folder (TempOutput) to prevent cluttering the main folder.
md %TempOutput% > nul 2>&1
cd %TempOutput%

REM Use nextpnr-himbaechel to check for the OSS CAD Suite presence. If nextpnr
REM works, then everything else should because it has the most dependencies.
nextpnr-himbaechel -V > NUL 2>&1
if %errorlevel% NEQ 0 (
	echo OSS CAD Suite Not found. Download the Windows package from 
	echo github.com/YosysHQ/oss-cad-suite-build and extract it on the
	echo E80 Toolchain installation folder, so that
	echo "%ToolchainFolder%\oss-cad-suite" contains bin, lib, etc.
	echo ** Press any key to exit **
	pause > nul
)

REM Use openFPGALoader to check for the Olimex GateMate board; if not found
REM continue, assuming the user will connect it now.
openfpgaloader -b olimex_gatemateevb --detect > NUL 2>&1
if %errorlevel% NEQ 0 (
	echo Board not found. If it's connected and PWR_LED1 is on, check for
	echo a dirtyJtag device under "Universal Serial Bus devices". If it's
	echo on "Other devices", update its driver from the "Driver" folder.
	echo If you just forgot to connect it, you can do it now.
	echo.
)

REM check if bitstream exists and size > 0, otherwise start compilation
if exist "%bitstream%" for %%I in ("%bitstream%") do if %%~zI GTR 0 (
	echo    Previous bitstream found.
	goto :flashprompt
)

REM Each step writes everything on its own log. If the step fails, Sc1 will
REM be called to open the step's log, and a Lua script will force a refresh
REM on the opened tab (in case the log was opened earlier) and move the cursor
REM to the end of the document.

:start
echo 1. Elaboration (ghdl)
set log=ghdl.log
set command=ghdl -i --std=08 ..\..\..\VHDL\*.vhd ..\Board.vhd
copy NUL %log% > NUL
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

echo 2. Synthesis (yosys) -- slow
set log=yosys.log
set command=yosys -p "read_verilog Interface.v; synth_gatemate -top Interface -luttree -nomx8 -nomult; write_json Interface.json"
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

echo 3. Place and Route (nextpnr) -- SLOW!
set log=nextpnr.log
set command=nextpnr-himbaechel --device CCGM1A1 --json Interface.json -o ccf=..\E80.ccf -o out=Interface.impl --router router2 --ignore-loops --freq 2 --timing-allow-fail
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

echo 4. Bitstream Packing (gmpack)
set log=gmpack.log
set command=gmpack Interface.impl Interface.bit -v
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

:openfpgaloader
echo 5. FPGA Flashing (openfpgaloader)
set log=openfpgaloader.log
set command=openfpgaloader -b olimex_gatemateevb Interface.bit
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel%==0 (
	echo    Done.
) else (
	echo    Failed! Is the board connected?
)
:flashprompt
echo ** Hit [1] to recompile or [5] to reflash **
choice /C 15 /N > nul
if %errorlevel%==1 goto :start
if %errorlevel%==2 goto :openfpgaloader
goto :flashprompt


:error
echo    Failed! Opening %log%
start /min  ..\..\..\Sc1 "%TempOutput%\%log%"
echo ** Hit [1] to recompile **
choice /C 1 /N > nul
if %errorlevel%==1 goto :start