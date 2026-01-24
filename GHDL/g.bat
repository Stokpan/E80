@echo off
setlocal
echo Running the design in GHDL for %2 or until Halt.

REM add local GHDL & GTKWave paths for portable installation
set PATH=%~dp0bin;%~dp0GTKWave\bin;%path%

REM change to a temporary folder in homedir
cd %~dp0
rd /s /q TempOutput > nul 2>&1
md TempOutput > nul 2>&1
cd TempOutput

REM Importing and parsing all files in GHDL
ghdl -i --std=08 ..\..\VHDL\*.vhd
if %errorlevel% NEQ 0 goto :error

REM Making the design with %1 as top unit in GHDL
ghdl -m --std=08 -Wno-hide %1
if %errorlevel% NEQ 0 goto :error

REM Running the design in GHDL for %2 or until Halt
ghdl -r --std=08 %1 --stop-time=%2 --wave=%1.ghw
if %errorlevel% NEQ 0 goto :error

REM Close the previous GTKWave window
taskkill /im gtkwave.exe >nul 2>&1
echo Opening waveforms in GTKWave.
REM Through powershell, otherwise GTKWave will lock the caller process (Sc1) until it's closed!
powershell -Command "Start-Process gtkwave.exe -ArgumentList '..\%1.gtkw --rcvar \"hide_sst on\"'"

goto :end

:error
echo --------------------------------------------------------------
pause

:end
exit