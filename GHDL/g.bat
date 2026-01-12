@echo off
setlocal
echo Running the design in GHDL for %2 or until Halt.

REM change to the GHDL batch homedir to allow for relative paths
cd %~dp0
REM add local GHDL & GTKWave paths for portable installation
set PATH=%PATH%;bin;GTKWave\bin

REM Importing and parsing all files in GHDL
ghdl -i --std=08 ..\VHDL\*.vhd
if %errorlevel% NEQ 0 goto :error

REM Making the design with %1 as top unit in GHDL
ghdl -m --std=08 -Wno-hide %1
if %errorlevel% NEQ 0 goto :error

REM Running the design in GHDL for %2 or until Halt
ghdl -r --std=08 %1 --stop-time=%2 --wave=%1.ghw
if %errorlevel% NEQ 0 goto :error

echo Opening waveforms in GTKWave.
taskkill /im gtkwave.exe >nul 2>&1
powershell -Command "Start-Process gtkwave.exe -ArgumentList '%1.gtkw --rcvar \"hide_sst on\"'"

goto :end

:error
echo --------------------------------------------------------------
pause

:end
exit