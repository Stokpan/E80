@echo off

REM change to the GHDL batch homedir to allow for relative paths
cd %~dp0
REM add GHDL & GTKWave paths for portable installation
set PATH=%PATH%;GHDL\bin;GTKWave\bin

echo E80 parametric GHDL-GTKwave simulation batch file

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
if exist "%~1\Computer.vhd" goto :parameter2_test
echo Missing 1st parameter, the E80 VHDL directory (eg. ..\VHDL)
goto :error

:parameter2_test
if "%~2" NEQ "" goto :exec
echo Missing 2nd parameter, the top design unit (eg. alu_tb)
goto :error

:parameter3_test
if "%~3" NEQ "" goto :exec
echo Missing 3rd parameter, the simulation duration (eg. 800ps)
goto :error

:exec
echo --------------------------------------------------------------
echo 1. Import and parse all VHDL files into the workspace :
echo    ghdl -i --std=08 %1\*.vhd
ghdl -i --std=08 %1\*.vhd
if %errorlevel% NEQ 0 goto :error
echo --------------------------------------------------------------
echo 2. Make the design with %2 as top unit :
echo    ghdl -m --std=08 -Wno-hide %2
ghdl -m --std=08 -Wno-hide %2
if %errorlevel% NEQ 0 goto :error
echo --------------------------------------------------------------
echo 3. Run (simulate) the design for %3 :
echo    ghdl -r --std=08 %2 --stop-time=%3 --wave=%2.ghw
ghdl -r --std=08 %2 --stop-time=%3 --wave=%2.ghw
if %errorlevel% NEQ 0 goto :error
echo --------------------------------------------------------------
echo 4. Opening GTKWave config %2.gtkw :
echo    gtkwave %2.gtkw
gtkwave %2.gtkw --rcvar "hide_sst on"
if %errorlevel% NEQ 0 (
echo --------------------------------------------------------------
	echo 5. File not found; opening wave without config :
	echo    gtkwave %2.ghw
	gtkwave %2.ghw
)
echo --------------------------------------------------------------

goto :end

:error
pause

:end