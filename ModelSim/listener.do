# Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>
# ModelSim listener script
# If the E80sim file exists, it deletes it and runs the c.do script

proc checkE80sim {} {
	if {[file exists E80sim]} {
		file delete E80sim
		if {![file exists E80sim]} {
			do sim.do
		}
	}
	after 500 checkE80sim
}
checkE80sim