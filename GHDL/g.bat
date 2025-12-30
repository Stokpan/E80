@echo off

REM change to the GHDL batch homedir to allow for relative paths
cd %~dp0
REM add local GHDL & GTKWave paths for portable installation
set PATH=%PATH%;bin;GTKWave\bin

:ghdl_test
ghdl > NUL 2>&1
if %errorlevel% NEQ 9009 goto :gtkwave_test
echo Install GHDL and add ghdl\bin to your path
goto :error

:gtkwave_test
gtkwave -h > NUL 2>&1
if %errorlevel% NEQ 9009 goto :parameter1_test
echo Install GTKwave and add gtkwave\bin to your path
goto :error

:parameter1_test
if "%~1" NEQ "" goto :parameter2_test
echo Missing 1st parameter, the top design unit (eg. alu_tb)
goto :error

:parameter2_test
if "%~2" NEQ "" goto :exec
echo Missing 2nd parameter, the simulation duration (eg. 800ps)
goto :error

:exec
echo Importing and parsing all files by GHDL
ghdl -i --std=08 ..\VHDL\*.vhd
if %errorlevel% NEQ 0 goto :error

echo Making the design with %1 as top unit in GHDL
ghdl -m --std=08 -Wno-hide %1
if %errorlevel% NEQ 0 goto :error

echo Running the design by GHDL for %2
ghdl -r --std=08 %1 --stop-time=%2 --wave=%1.ghw
if %errorlevel% NEQ 0 goto :error

echo Opening GTKWave config %1.gtkw
taskkill /im gtkwave.exe >nul 2>&1
powershell -Command "Start-Process gtkwave.exe -ArgumentList '%1.gtkw --rcvar \"hide_sst on\"'"

goto :end

:error
echo --------------------------------------------------------------
pause

:end
exit