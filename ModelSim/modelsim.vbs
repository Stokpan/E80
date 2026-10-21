' E80 ModelSim calling vbscript
' Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
' Runs ModelSim with a listener script to allow updating the simulation without
' re-running ModelSim. The 0 argument on the Run Method hides the listener
' window and the output is redirected to E80lock which is undeletable while
' ModelSim is running, so m.bat can detect ModelSim and prevent new instances.
' Vbscript is used for the same reason with GTKWave: a normal command
' line blocks the Sc1 editor until ModelSim/GTKWave is closed.

CreateObject("WScript.Shell").Run "cmd /c vsim -do ""do listener.do"" > E80lock", 0