@echo off

echo ==========================================
echo E80 Toolchain Dependencies Download Script
echo You need to run this script within the E80
echo Installer folder and then compile setup.nsis
echo using the strlen_8192 version from
echo https://sourceforge.net/projects/nsis
echo ==========================================

echo Creating directories...
mkdir ExtrasIgnore
cd ExtrasIgnore
mkdir GHDL
mkdir GHDL\GTKwave

echo Downloading Sc1.exe...
curl -# -L -o Sc1.exe https://sourceforge.net/projects/scintilla/files/SciTE/5.6.2/Sc32_562.exe/download
echo.

echo Downloading GHDL...
curl -# -L -o ghdl.zip https://github.com/ghdl/ghdl/releases/download/v6.0.0/ghdl-mcode-6.0.0-mingw64.zip
tar -xf ghdl.zip -C GHDL
echo.

echo Downloading GTKWave...
curl -# -L -o gtkwave.zip https://sourceforge.net/projects/gtkwave/files/gtkwave-3.3.100-bin-win32/gtkwave-3.3.100-bin-win32.zip/download
tar -xf gtkwave.zip -C GHDL
echo.

echo Cleaning up redudant files
del ghdl.zip
del gtkwave.zip
rd /s /q GHDL\include
rd /s /q GHDL\lib\ghdl\vendors
rd /s /q GHDL\lib\ghdl\src\synopsys
rd /s /q GHDL\lib\ghdl\src\upf
rd /s /q GHDL\lib\ghdl\src\vital2000
rd /s /q GHDL\lib\ghdl\src\vital95
rd /s /q GHDL\GTKwave\share
rd /s /q GHDL\GTKwave\lib\tk8.5
rd /s /q GHDL\GTKwave\lib\tcl8\8.2
rd /s /q GHDL\GTKwave\lib\tcl8\8.3
rd /s /q GHDL\GTKwave\lib\tcl8.5\encoding
rd /s /q GHDL\GTKwave\lib\tcl8.5\http1.0
rd /s /q GHDL\GTKwave\lib\tcl8.5\msgs
rd /s /q GHDL\GTKwave\lib\tcl8.5\opt0.4
rd /s /q GHDL\GTKwave\lib\tcl8.5\tzdata
rd /s /q GHDL\GTKwave\lib\tcl8\8.5
del GHDL\mingw64.requirements
del GHDL\lib\ghdl\ansi_color.sh
del GHDL\lib\libghdl-6_0_0.dll
del GHDL\lib\libghdl.a
del GHDL\lib\libghdl.link
del GHDL\lib\libghdlvpi.dll
del GHDL\lib\libghw.dll
del GHDL\lib\libgnat-15.dll
del GHDL\lib\libwinpthread-1.dll
del GHDL\lib\libgcc_s_seh-1.dll
del GHDL\GTKwave\bin\evcd2vcd.exe
del GHDL\GTKwave\bin\fst2vcd.exe
del GHDL\GTKwave\bin\fstminer.exe
del GHDL\GTKwave\bin\ghwdump.exe
del GHDL\GTKwave\bin\lxt2miner.exe
del GHDL\GTKwave\bin\lxt2vcd.exe
del GHDL\GTKwave\bin\rtlbrowse.exe
del GHDL\GTKwave\bin\shmidcat.exe
del GHDL\GTKwave\bin\twinwave.exe
del GHDL\GTKwave\bin\vcd2fst.exe
del GHDL\GTKwave\bin\vcd2lxt.exe
del GHDL\GTKwave\bin\vcd2lxt2.exe
del GHDL\GTKwave\bin\vcd2vzt.exe
del GHDL\GTKwave\bin\vermin.exe
del GHDL\GTKwave\bin\vzt2vcd.exe
del GHDL\GTKwave\bin\vztminer.exe
del GHDL\GTKwave\bin\xml2stems.exe
echo.

pause