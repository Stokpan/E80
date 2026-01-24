@echo off
echo ----------------------------------------------------------------------
echo This will flash your E80 bitstream to the Olimex GateMateA1-EVB board.
echo ----------------------------------------------------------------------
REM Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

setlocal
set workdir=TempOutput
cd %~dp0
md %workdir% > nul 2>&1
cd %workdir%

set bitstream=Interface.bit

..\openfpgaloader -b olimex_gatemateevb --detect > NUL 2>&1
if %errorlevel% NEQ 0 (
	echo Board not found. If it's connected and PWR_LED1 is on, check for
	echo a dirtyJtag device under "Universal Serial Bus devices".
	echo If not, install the driver; if yes, try pressing FPGA_RST1.
	echo Press any key to exit
	pause > nul
	exit /b
)

:check_bistream
REM check if bitstream exists and size > 0, otherwise run synth.bat
powershell -Command "if ((Get-Item '%bitstream%' -ErrorAction SilentlyContinue).Length -gt 0) { exit 0 } else { exit 1 }"
if %errorlevel%==0 goto :bitstream_exists
	echo %workdir%\%bitstream% file doesn't exist; running synth.bat to create it.
	..\synth.bat
:bitstream_exists

REM set and create a null logfile
set log=openfpgaloader.log
copy NUL %log% > NUL
REM run command and log output
set command=..\openfpgaloader -c dirtyJtag %bitstream%
:openfpgaloader
echo -------------------------------------------------------------------------- >> %log%
echo %time% -- %command% >> %log%
echo -------------------------------------------------------------------------- >> %log%
%command% >> %log% 2>&1
if %errorlevel%==0 (
	echo Done.
) else (
	echo Failed! Try pressing the FPGA_RST1 button.
)
echo Hit [Esc] to exit or any other key to reflash.
REM clear keyboard buffer and read Esc key via powershell
for /f %%k in ('powershell -Command "while([Console]::KeyAvailable){[void][Console]::ReadKey($true)}; $k=[Console]::ReadKey($true); if($k.Key -eq 'Escape'){1}"') do (
	if %%k==1 exit /b
)
goto :openfpgaloader