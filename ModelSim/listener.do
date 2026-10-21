# Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
# ModelSim listener TCL script
# The E80sim file is created by m.bat which is triggered by the user,
# so when it exists, it signifies a simulation (sim.do) request.

proc checkE80sim {} {
	if {[file exists E80sim]} {
		file delete E80sim
		if {![file exists E80sim]} {
			quietly do sim.do
		}
	}
	after 500 quietly checkE80sim
}
quietly checkE80sim