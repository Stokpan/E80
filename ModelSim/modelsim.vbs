' E80 ModelSim calling vbscript
' Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
' Runs ModelSim with a listener script to allow updating the simulation without
' re-running ModelSim. Running through vbscript instead of a normal command
' line solves the problem of ModelSim locking the Sc1 editor until closed.
' The 0 argument on the Run Method hides the listener window.

CreateObject("WScript.Shell").Run "vsim -do ""do listener.do""", 0