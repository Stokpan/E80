' E80 GTKWave calling vbscript
' Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
' Runs GTKWave with a gtkw file (usually sim.gtkw) as a required argument.
' Running through vbscript instead of a normal command line solves the problem
' of GTKWave locking the Sc1 editor until closed.

CreateObject("WScript.Shell").Run "GTKwave\bin\gtkwave.exe " & WScript.Arguments(0)