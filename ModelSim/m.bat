@echo off
REM E80 ModelSim automation batch
REM Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
REM Runs ModelSim through a listener script to allow updating the simulation
REM without re-running ModelSim.

REM change to the ModelSim project dir to allow for relative paths
cd %~dp0

:modelsim_test
vsim -c -help > NUL 2>&1
if %errorlevel% NEQ 9009 goto :pipe
echo Install ModelSim or use GHDL/GTKWave for simulation
goto :error

:pipe
echo Updating simulation on ModelSim.
REM E80sim is captured and then deleted by the listener.do script that is
REM running on ModelSim. If the file is not deleted within 3 seconds, it means
REM ModelSim is not running with its listener script, so we must first run it.
echo 1 > E80sim
call :sleep 3
if exist "E80sim" goto :listener
goto :end

:listener
echo Starting ModelSim (keep it open to avoid this delay).
REM ModelSim is run through vbscript for the same reason with GTKWave; if it's
REM run through the command line, it will lock the Sc1 editor until closed.
modelsim.vbs
goto :end

:error
pause

:end
exit

:sleep
ping 127.0.0.1 -n %1 -w 1000 > NUL