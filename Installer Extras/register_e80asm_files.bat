@echo off
echo Registering .e80asm files for the current user...
reg add "HKCU\Software\Classes\E80ASMfile" /ve /t REG_SZ /d "E80 Assembly Source" /f >nul
reg add "HKCU\Software\Classes\E80ASMfile\DefaultIcon" /ve /t REG_SZ /d "%~dp0e80icon.ico" /f >nul
reg add "HKCU\Software\Classes\E80ASMfile\shell\open\command" /ve /t REG_SZ /d "\"%~dp0Sc1.exe\" \"%%1\"" /f >nul
reg add "HKCU\Software\Classes\.e80asm" /ve /t REG_SZ /d "E80ASMfile" /f >nul
echo Refreshing icons...
powershell -Command "$code = '[DllImport(\"shell32.dll\")]public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);'; $type = Add-Type -MemberDefinition $code -Name Win32 -Namespace Shell -PassThru; $type::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)"
echo Done!
pause