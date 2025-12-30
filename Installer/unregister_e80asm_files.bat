@echo off
echo Unregistering E80ASM from current user...
reg delete "HKCU\Software\Classes\.e80asm" /f >nul 2>&1
reg delete "HKCU\Software\Classes\E80ASMfile" /f >nul 2>&1
echo Refreshing icons...
powershell -Command "$code = '[DllImport(\"shell32.dll\")]public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);'; $type = Add-Type -MemberDefinition $code -Name Win32 -Namespace Shell -PassThru; $type::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)"
echo Done.
pause