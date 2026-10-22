@echo off
REM -----------------------------------------------------------------------
REM E80 GateMate Synthesis Batch
REM Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
REM Runs all necessary tools from the OSS CAD Suite with the necessary
REM configuration options to drive the build of the E80 VHDL design (including
REM the user's assembled Program.vhd) to the board.
REM -----------------------------------------------------------------------

title E80 GateMate Synthesis Batch
echo -----------------------------------------------------------------------
echo                       E80 GateMate Synthesis Batch
echo This will synthesize E80's VHDL code (including your assembled program)
echo and then flash the output bitstream to the Olimex GateMateA1-EVB board.
echo -----------------------------------------------------------------------

setlocal
set TopUnit=Interface

REM Get a clean path to the Toolchain installation folder (first cd to it)
cd /d "%~dp0..\.."
set ToolchainFolder=%cd%\

if not defined YOSYSHQ_ROOT (
	set YOSYSHQ_ROOT=%ToolchainFolder%oss-cad-suite\
)
REM Add our Toolchain GHDL folder -- the GHDL plugin is not built into
REM the Windows version of the OSS-CAD-Suite
set PATH=%YOSYSHQ_ROOT%bin;%YOSYSHQ_ROOT%lib;%ToolchainFolder%GHDL\bin;%path%

REM OSS-CAD-Suite component paths from its environment.bat
set PYTHON_EXECUTABLE=%YOSYSHQ_ROOT%lib\python3.exe
set OPENFPGALOADER_SOJ_DIR=%YOSYSHQ_ROOT%share\openFPGALoader

REM move to work folder (TempOutput) to prevent cluttering the main folder
set TempOutput=%~dp0TempOutput
md "%TempOutput%" > nul 2>&1
cd "%TempOutput%"

REM Use nextpnr-himbaechel to check for the OSS CAD Suite presence. If nextpnr
REM works, then everything else should because it has the most dependencies.
nextpnr-himbaechel -V > NUL 2>&1
if %errorlevel% NEQ 0 (
	echo    The OSS CAD Suite is not found on the Toolchain folder.
	echo    To install it, see Boards\Yosys_GateMateA1\README.md
	echo ** Press any key to exit **
	pause > nul
	exit /b
)

REM Use openFPGALoader to check for the Olimex GateMate board; if not found
REM continue, assuming the user will connect it during compilation.
openfpgaloader -b olimex_gatemateevb --detect > NUL 2>&1
if %errorlevel% NEQ 0 (
    REM Check if the board is found on the device manager, using the errorlevel
    REM environment variable (not %errorlevel%) to avoid delayed expansion.
	pnputil /enum-devices /connected | findstr /i "VID_1209&PID_C0CA" > NUL
	if errorlevel 1 (
		echo    Board not found! Please connect it with a data cable.
	) else (
		echo    The board is connected but the driver is missing! Please install
		echo    it according to Boards\Yosys_GateMateA1\README.md.
	)
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

REM get the time (t1) before the 1st step
call :now t1

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

echo 2. Synthesis (yosys)
set log=yosys.log
set command=yosys -p "read_verilog %TopUnit%.v; synth_gatemate -top %TopUnit% -luttree -nomx8; write_json %TopUnit%.json"
copy NUL %log% > NUL
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel% NEQ 0 goto :error

REM get the time (t2) after the 2nd step
call :now t2
REM if the build crossed midnight, add a day to fix t2 restarting from zero
if %t2% LSS %t1% set /a t2+=8640000
REM nextpnr takes about 10x steps 1 & 2; round estimate to nearest 10 s
set /a est=((t2-t1)*10/100+5)/10*10

echo 3. Place and Route (nextpnr) -- estimated %est% seconds
set log=nextpnr.log
set command=nextpnr-himbaechel --device CCGM1A1 --json %TopUnit%.json -o ccf=..\E80.ccf -o out=%TopUnit%.impl --freq 2 --placer-heap-beta 0.3
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
exit /b

REM Set the variable named %1 to the time of day in centiseconds
:now
for /f "tokens=1-4 delims=:., " %%a in ("%time%") do set /a "%1=((100%%a%%100*60+100%%b%%100)*60+100%%c%%100)*100+100%%d%%100"
exit /b