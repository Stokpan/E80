@echo off
REM GHDL/GTKWave batch
REM Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
REM Example usage: g sim 100ns

REM Set local GHDL & GTKWave paths for portable installation
setlocal
set PATH=%~dp0bin;%~dp0GTKWave\bin;%path%

REM Set default options
if "%~1"=="" (
	set top=sim
) else (
	set top=%1
)
if "%~2"=="" (
	set duration=100ns
) else (
	set duration=%2
)

echo Running %top% in GHDL for %duration% or until Halt.

REM Change to a temporary folder to prevent cluttering homedir with temp files
cd %~dp0
rd /s /q TempOutput > nul 2>&1
md TempOutput > nul 2>&1
cd TempOutput

REM Import and parsing all files in GHDL
ghdl -i --std=08 ..\..\VHDL\*.vhd
if %errorlevel% NEQ 0 goto :end

REM Make the design with %top% as top unit in GHDL
ghdl -m --std=08 -Wno-hide %top%
if %errorlevel% NEQ 0 goto :end

REM Run the design in GHDL for %duration% or until Halt
ghdl -r --std=08 %top% --stop-time=%duration% --wave=%top%.ghw
if %errorlevel% NEQ 0 goto :end

REM Close the previous GTKWave window
taskkill /im gtkwave.exe >nul 2>&1
echo Opening waveforms in GTKWave.
REM Open GTKWave through powershell, otherwise it will lock the caller process (Sc1) until closed
powershell -Command "Start-Process gtkwave.exe -ArgumentList '..\%top%.gtkw --rcvar \"hide_sst on\"'"

:end