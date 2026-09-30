@echo off
REM E80 ModelSim automation batch
REM Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
REM Runs ModelSim through a listener script to allow updating the simulation
REM without re-running ModelSim.

REM change to the ModelSim project dir to allow for relative paths
cd /d "%~dp0"

REM check if ModelSim is installed
vsim -version > NUL 2>&1
if errorlevel 9009 (
	echo Install ModelSim or use GHDL/GTKWave for simulation
	exit
)

REM E80lock is created and locked by the listener; if it can be deleted (or
REM it doesn't exist) it means the listener isn't running.
del E80lock > NUL 2>&1
if not exist E80lock (
	echo Starting ModelSim -- keep it open for updates.
	REM the comments in modelsim.vbs explain why Vbscript is used
	modelsim.vbs
) else (
	echo Updating ModelSim.
)

REM creating E80sim triggers simulation through the listener
echo 1 > E80sim