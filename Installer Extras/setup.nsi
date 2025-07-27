; E80 Toolchain Installer Script
!include "MUI2.nsh"
!include "FileFunc.nsh"

Name "E80 Toolchain"
OutFile "E80_Toolchain_Setup.exe"
Unicode True

; improved compression
SetCompressor /SOLID lzma

; Preferred installation folder (Standard Windows Program Files)
InstallDir "$%HOMEDRIVE%\E80Toolchain"
  
; Get installation folder from registry if previously installed
InstallDirRegKey HKCU "Software\E80Toolchain" ""

; Request User privileges (No UAC prompt)
RequestExecutionLevel user

; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "e80icon.ico" 
!define MUI_UNICON "e80icon.ico"
!define MUI_HEADERIMAGE

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

; Check if we can use the preferred installation folder
Function .onInit
	; Attempt to create the directory to test permissions
	ClearErrors
	CreateDirectory "$INSTDIR"
	IfErrors Fallback TryCleanup
	Fallback:
		; Switch to Local AppData
		StrCpy $INSTDIR "$LOCALAPPDATA\E80Toolchain"
		Goto Done
	TryCleanup:
		; Remove the created folder (RMDir only deletes empty folders)
		RMDir "$INSTDIR"
		Goto Done
	Done:
FunctionEnd

; Installer Sections
Section "E80 Toolchain (Required)" SecCore
	SectionIn RO
	; Subdirectories
	SetOutPath "$INSTDIR\GHDL"
	File /r "GHDL\*.*"
	SetOutPath "$INSTDIR\GTKwave"
	File /r "GTKwave\*.*"
	SetOutPath "$INSTDIR\VHDL"
	File /r "..\VHDL\*.*"
	SetOutPath "$INSTDIR\Gowin"
	File /r "..\Gowin\*.*"
	SetOutPath "$INSTDIR\ModelSim"
	File /r "..\ModelSim\*.*"
	SetOutPath "$INSTDIR"

	; Legal / Notices
    File "Licenses.txt"
    File "..\LICENSE"

	; Executables and Config
	File "Sc1.exe"
	File "Sc1.License.txt"
	File "..\Assembler\E80ASM.exe"
	File "SciTEGlobal.properties"
	File "e80asm.lua"
	File "..\GHDL Scripts\g.bat"
	
	; Source Examples & Templates
	File "..\Assembler\divmul.e80asm"
	File "..\Assembler\template.vhd"
	File "..\GHDL Scripts\computer_tb.gtkw"

	; Icon
	File "e80icon.ico"

	; Portable Scripts (For USB use)
	File "register_e80asm_files.bat"
	File "unregister_e80asm_files.bat"

	; Store Install Path
	WriteRegStr HKCU "Software\E80Toolchain" "" $INSTDIR

	; Create Uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"

	; Define the Registry Key path (Current User)
	!define REG_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\E80Toolchain"

	; Write the uninstall keys for Windows
	WriteRegStr HKCU "${REG_UNINSTALL}" "DisplayName" "E80 Toolchain"
	WriteRegStr HKCU "${REG_UNINSTALL}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKCU "${REG_UNINSTALL}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKCU "${REG_UNINSTALL}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKCU "${REG_UNINSTALL}" "DisplayIcon" "$\"$INSTDIR\e80icon.ico$\""
	WriteRegStr HKCU "${REG_UNINSTALL}" "Publisher" "Panos Stokas"
	WriteRegStr HKCU "${REG_UNINSTALL}" "DisplayVersion" "1.1"
	WriteRegDWORD HKCU "${REG_UNINSTALL}" "NoModify" 1
	WriteRegDWORD HKCU "${REG_UNINSTALL}" "NoRepair" 1

	; Start Menu Shortcuts
	CreateDirectory "$SMPROGRAMS\E80 Toolchain"
	CreateShortcut "$SMPROGRAMS\E80 Toolchain\E80 Editor.lnk" "$INSTDIR\Sc1.exe" "" "$INSTDIR\e80icon.ico" 0
	CreateShortcut "$SMPROGRAMS\E80 Toolchain\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Register File Associations (Current User)" SecAssoc
	; Define the ProgID in User Registry
	WriteRegStr HKCU "Software\Classes\E80ASMfile" "" "E80 Assembly Source"
	; Define the Default Icon
	WriteRegStr HKCU "Software\Classes\E80ASMfile\DefaultIcon" "" "$INSTDIR\e80icon.ico"
	; Define the Open Command (Note: $\" escapes the quotes for the string)
	WriteRegStr HKCU "Software\Classes\E80ASMfile\shell\open\command" "" "$\"$INSTDIR\Sc1.exe$\" $\"%1$\""
	; Associate .e80asm with ProgID
	WriteRegStr HKCU "Software\Classes\.e80asm" "" "E80ASMfile"
	; Refresh Icons (Native API call, no side effects)
	System::Call 'shell32.dll::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)'
SectionEnd

;--------------------------------
; Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SecCore} "Sc1 editor, E80 Assembler, GHDL, GTKWave, and all the necessary configuration to allow simulation of a program on E80 by pressing F5 on Sc1."
	!insertmacro MUI_DESCRIPTION_TEXT ${SecAssoc} "Associate .e80asm files with Sc1."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Uninstaller Section
Section "Uninstall"
	; Remove Registry Keys (Main settings)
	DeleteRegKey HKCU "Software\E80Toolchain"
	; Remove Associations (From User Classes)
	DeleteRegKey HKCU "Software\Classes\E80ASMfile"
	DeleteRegKey HKCU "Software\Classes\.e80asm"
	; Refresh Icons
	System::Call 'shell32.dll::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)'
	; Remove Files and Directories
	; RMDir /r is safer here because we are inside AppData, not Program Files.
	RMDir /r "$INSTDIR"
	; Remove Shortcuts
	RMDir /r "$SMPROGRAMS\E80 Toolchain"
    ; Remove the uninstaller entry from Windows Registry
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\E80Toolchain"
SectionEnd