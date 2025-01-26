@echo off

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
if "%~1" NEQ "" goto :parameter2_test
echo Missing top unit on 1st parameter
goto :error

:parameter2_test
if "%~2" NEQ "" goto :exec
echo Missing duration on 2nd parameter
goto :error

:exec
echo --------------------------------------------------------------
echo 1. Import and parse all VHDL files into the workspace :
echo    ghdl -i --std=08 ..\VHDL\*.vhd
ghdl -i --std=08 ..\VHDL\*.vhd
if %errorlevel% NEQ 0 goto :error
echo --------------------------------------------------------------
echo 2. Make the design with %1 as top unit :
echo    ghdl -m --std=08 -Wno-hide %1
ghdl -m --std=08 -Wno-hide %1
if %errorlevel% NEQ 0 goto :error
echo --------------------------------------------------------------
echo 3. Run (simulate) the design for %2 :
echo    ghdl -r --std=08 %1 --stop-time=%2 --wave=%1.ghw
ghdl -r --std=08 %1 --stop-time=%2 --wave=%1.ghw
if %errorlevel% NEQ 0 goto :error
echo --------------------------------------------------------------
echo 4. Opening GTKWave config %1.gtkw :
echo    gtkwave %1.gtkw
gtkwave %1.gtkw --rcvar "hide_sst on"
if %errorlevel% NEQ 0 (
echo --------------------------------------------------------------
	echo 5. File not found; opening wave without config :
	echo    gtkwave %1.ghw
	gtkwave %1.ghw
)
echo --------------------------------------------------------------

goto :end

:error
pause

:end