; E80 Toolchain Installer Script
; Copyright (C) 2025 Panos Stokas <panos.stokas@hotmail.com>
; Requires the strlen_8192 version from https://sourceforge.net/projects/nsis

!include "MUI2.nsh"
!include "FileFunc.nsh"

Name "E80 Toolchain"
OutFile "E80_Toolchain_Setup.exe"
Unicode True

; improved compression
SetCompressor /SOLID lzma

; Preferred installation folder
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
Section "Portable requirements" SecCore
	SectionIn RO

	; Copy files
	SetOutPath "$INSTDIR\GHDL"
	File /r "..\GHDL\*.*"

	SetOutPath "$INSTDIR\VHDL"
	File /r "..\VHDL\*.*"

	SetOutPath "$INSTDIR\ModelSim"
	File /r "..\ModelSim\*.*"

	SetOutPath "$INSTDIR\Assembler"
	File "..\Assembler\E80ASM.exe"
	File "..\Assembler\template.vhd"
	File "..\Assembler\a.bat"

	SetOutPath "$INSTDIR\Boards"
	File /r "..\Boards\*.*"

	SetOutPath "$INSTDIR"
	File "3rd party Licenses.txt"
	File "..\Assembler\*.e80asm"
	File "..\LICENSE"
	File "SciTEGlobal.properties"
	File "e80asm.lua"
	File "e80icon.ico"
	File /r "ExtrasIgnore\*.*"

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

Section "Register .e80asm" SecAssoc
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

Section /o "Layout for ModelSim" SecModelSim
	; E80 Layout (requires the strlen_8192 nsis build)
	WriteRegStr HKCU "SOFTWARE\Model Technology Incorporated\ModelSim" "LayoutV5%2EE80" "vertical {{{{{.main_pane.process {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.locals {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.details {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 1 na {}} {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na paned {.main_pane.wave {-height 556 -hide 0 -minsize 50 -stretch always -width 1440} 533 na {} .main_pane.memdata {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.source1 {-height 600 -hide 1 -minsize 50 -width 600} 0 na {} .main_pane.source2 {-height 600 -hide 1 -minsize 50 -width 600} 0 na {} .main_pane.source3 {-height 600 -hide 1 -minsize 50 -width 600} 0 na {} .main_pane.source4 {-height 600 -hide 1 -minsize 50 -width 600} 0 na {} .main_pane.source5 {-height 600 -hide 1 -minsize 50 -width 600} 0 na {} .main_pane.source {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.dataflow {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.list {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.fsmview {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.msgviewer {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.triageviewer {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.atv {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.schematic {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.tracker {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.browser {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.canalysis {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.duranked {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.watch {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.ranked {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.calltree {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.structural {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.profiledetails {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.assertions {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.fcovers {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.covergroups {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.classtree {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.classgraph {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.trender {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.capacity {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.memdata1 {-height 600 -hide 1 -minsize 50 -width 600} 556 na {}} {-height 556 -hide 0 -minsize 50 -stretch always -width 1440} 1440 na tabbed} {-height 556 -hide 0 -minsize 50 -stretch always -width 1440} 556 na paned {{.main_pane.library {-height 215 -hide 0 -minsize 50 -stretch always -width 317} 215 na {} .main_pane.project {-height 215 -hide 0 -minsize 50 -stretch always -width 317} 256 na {} .main_pane.memory {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.structure {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.files {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.fsmlist {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.powerstatelist {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.stackview {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 0 na {} .main_pane.instance {-height 600 -hide 1 -minsize 50 -stretch always -width 600} 238 na {}} {-height 238 -hide 0 -minsize 50 -stretch always -width 317} 317 na tabbed {.main_pane.objects {-height 238 -hide 0 -minsize 50 -width 336} 238 na {}} {-height 238 -hide 0 -minsize 50 -stretch always -width 336} 659 na paned {.main_pane.transcript {-height 238 -hide 0 -minsize 50 -stretch always -width 775} 238 na {}} {-height 238 -hide 0 -minsize 50 -width 775} 1440 na tabbed} {-height 238 -hide 0 -minsize 50 -width 1440} 800 na paned} {-height 800 -hide 0 -minsize 50 -stretch always -width 1440} 1440 na paned} {-height 800 -hide 0 -minsize 200 -stretch always -width 1440} 800 na paned}"
	; Enable E80 Layout everywhere (reduces cluttering and subsequent simulation waiting time)
	WriteRegStr HKCU "SOFTWARE\Model Technology Incorporated\ModelSim" "LayoutForDefault" "E80"
	WriteRegStr HKCU "SOFTWARE\Model Technology Incorporated\ModelSim" "LayoutForLoad" "E80"
	WriteRegStr HKCU "SOFTWARE\Model Technology Incorporated\ModelSim" "LayoutForLoadCov" "E80"
SectionEnd

; Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SecCore} "Sc1 editor, E80 Assembler, GHDL, GTKWave, and board-specific settings and scripts."
	!insertmacro MUI_DESCRIPTION_TEXT ${SecAssoc} "Associate .e80asm files with Sc1 for the current user."
	!insertmacro MUI_DESCRIPTION_TEXT ${SecModelSim} "Create and enable a custom E80 layout on ModelSim. You can use ModelSim's Layout menu to reset and delete the custom layout."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Uninstaller Section
Section "Uninstall"
	; Remove Registry Keys
	DeleteRegKey HKCU "Software\E80Toolchain"
	DeleteRegKey HKCU "Software\Classes\E80ASMfile"
	DeleteRegKey HKCU "Software\Classes\.e80asm"
	; Refresh Icons
	System::Call 'shell32.dll::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)'
	; Remove Files and Directories
	RMDir /r "$INSTDIR"
	RMDir /r "$SMPROGRAMS\E80 Toolchain"
	; Remove the uninstaller entry from Windows Registry
	DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\E80Toolchain"
SectionEnd