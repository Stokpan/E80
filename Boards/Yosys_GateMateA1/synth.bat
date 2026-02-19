@echo off
title E80 VHDL Synthesis batch
echo -----------------------------------------------------------------------
echo                        E80 VHDL Synthesis batch
echo This will synthesize the VHDL code (including your program's firmware),
echo and then flash the output bitstream to the Olimex GateMateA1-EVB board.
echo -----------------------------------------------------------------------
REM Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

setlocal
set TopUnit=Interface

REM Get a clean path to the Toolchain installation folder (first cd to it)
cd %~dp0..\..
set ToolchainFolder=%cd%\

if not defined YOSYSHQ_ROOT (
	set YOSYSHQ_ROOT=%ToolchainFolder%oss-cad-suite\
)
REM Add our Toolchain GHDL folder -- the GHDL plugin is not built into
REM the Windows version of the OSS-CAD-Suite
set PATH=%YOSYSHQ_ROOT%bin;%YOSYSHQ_ROOT%lib;%ToolchainFolder%GHDL\bin;%path%

REM OSS-CAD-Suite component paths from its environment.bat
set PYTHON_EXECUTABLE=%YOSYSHQ_ROOT%lib\python3.exe
set QT_PLUGIN_PATH=%YOSYSHQ_ROOT%lib\qt5\plugins
set QT_LOGGING_RULES=*=false
set GTK_EXE_PREFIX=%YOSYSHQ_ROOT%
set GTK_DATA_PREFIX=%YOSYSHQ_ROOT%
set GDK_PIXBUF_MODULEDIR=%YOSYSHQ_ROOT%lib\gdk-pixbuf-2.0\2.10.0\loaders
set GDK_PIXBUF_MODULE_FILE=%YOSYSHQ_ROOT%lib\gdk-pixbuf-2.0\2.10.0\loaders.cache
gdk-pixbuf-query-loaders.exe --update-cache
set OPENFPGALOADER_SOJ_DIR=%YOSYSHQ_ROOT%share\openFPGALoader

REM move to work folder (TempOutput) to prevent cluttering the main folder.
set TempOutput=%~dp0TempOutput
md %TempOutput% > nul 2>&1
cd %TempOutput%

REM Use nextpnr-himbaechel to check for the OSS CAD Suite presence. If nextpnr
REM works, then everything else should because it has the most dependencies.
nextpnr-himbaechel -V > NUL 2>&1
if %errorlevel% NEQ 0 (
	echo    OSS CAD Suite Not found. Download the Windows package from 
	echo    github.com/YosysHQ/oss-cad-suite-build and run it on the
	echo    E80 Toolchain installation folder, so that it extracts an
	echo    "oss-cad-suite" subfolder with bin, lib, etc.
	echo ** Press any key to exit **
	pause > nul
	exit /b
)

REM Use openFPGALoader to check for the Olimex GateMate board; if not found
REM continue, assuming the user will connect it during compilation.
openfpgaloader -b olimex_gatemateevb --detect > NUL 2>&1
if %errorlevel% NEQ 0 (
	echo    Board not found. If it's connected and PWR_LED1 is on, check for
	echo    a dirtyJtag device under "Universal Serial Bus devices". If it's
	echo    on "Other devices", update its driver from the "Driver" folder.
	echo    If you just forgot to connect it, you can do it now.
	echo.
)

REM check if bitstream exists and size > 0, otherwise start compilation
if exist "%TopUnit%.bit" for %%I in ("%TopUnit%.bit") do if %%~zI GTR 0 (
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
if %errorlevel% NEQ 0 goto :error
set command=ghdl -m --std=08 -Wno-hide %TopUnit%
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error
set command=ghdl --synth --std=08 --out=verilog %TopUnit%
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% > %TopUnit%.v 2>>%log%
if %errorlevel% NEQ 0 goto :error

echo 2. Synthesis (yosys) -- slow
set log=yosys.log
set command=yosys -p "read_verilog %TopUnit%.v; synth_gatemate -top %TopUnit% -luttree -nomx8 -nomult; write_json %TopUnit%.json"
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

echo 3. Place and Route (nextpnr) -- SLOW!
set log=nextpnr.log
set command=nextpnr-himbaechel --device CCGM1A1 --json %TopUnit%.json -o ccf=..\E80.ccf -o out=%TopUnit%.impl --router router2 --ignore-loops --freq 2 --timing-allow-fail --placer-heap-beta 0.3
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

echo 4. Bitstream Packing (gmpack)
set log=gmpack.log
set command=gmpack %TopUnit%.impl %TopUnit%.bit -v
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

:openfpgaloader
echo 5. FPGA Flashing (openfpgaloader)
set log=openfpgaloader.log
set command=openfpgaloader -b olimex_gatemateevb %TopUnit%.bit
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel%==0 (
	echo    Done.
) else (
	echo    Failed! Is the board connected? Try pressing the FPGA_RST1 button.
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