# E80 ModelSim simulation and layout TCL script
# Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

# Equivalent to @echo off, to reduce verbosity on the log pane
transcript quietly

# Stop previous simulation
quit -sim

# Open project and clear previous log 
project open e80.mpf
.main clear

# Compile all files & simulate the top unit (sim.vhd)
project compileall
vsim -quiet work.sim

# Switch to the project tab
view project

# Add signal waves (no need to WaveActivateNextPane {} 0)
add wave -noupdate /sim/CLK
add wave -noupdate -radix unsigned /sim/PC
add wave -noupdate -radix hexadecimal /sim/Instr1
add wave -noupdate -radix hexadecimal /sim/Instr2
add wave -noupdate -label Carry /sim/R(6)(7)
add wave -noupdate -label Zero /sim/R(6)(6)
add wave -noupdate -label Sign /sim/R(6)(5)
add wave -noupdate -label Overflow /sim/R(6)(4)
add wave -noupdate /sim/Halt

add wave -noupdate -label R0 -radix unsigned /sim/R(0)
add wave -noupdate -label R1 -radix unsigned /sim/R(1)
add wave -noupdate -label R2 -radix unsigned /sim/R(2)
add wave -noupdate -label R3 -radix unsigned /sim/R(3)
add wave -noupdate -label R4 -radix unsigned /sim/R(4)
add wave -noupdate -label R5 -radix unsigned /sim/R(5)
add wave -noupdate -label SP -radix unsigned /sim/R(7)

add wave -noupdate -radix unsigned /sim/RAM(251)
add wave -noupdate -radix unsigned /sim/RAM(252)
add wave -noupdate -radix unsigned /sim/RAM(253)
add wave -noupdate -radix unsigned /sim/RAM(254)
add wave -noupdate -radix binary /sim/DIPinput

add wave -noupdate -label Monitor -radix ascii /sim/MonitorVector
add wave -noupdate -label Monitor -radix binary /sim/MonitorArray

add wave -noupdate -radix hexadecimal /sim/RAM

# Format waves
configure wave -namecolwidth 104
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -rowmargin 4
configure wave -gridperiod 100
configure wave -timelineunits ps
set PrefSource(OpenOnBreak) 0

# Fine-tune zoom to fit 3 digits in a cycle and show waves
wave zoom range 0 4400
view wave

# Stop simulation when the Halt flag is raised; onbreak is needed
# for older ModelSim to prevent breaking listener.do
onbreak {resume}
when {/sim/Halt=='1'} {
	stop
	echo "Halt detected"
}

# Run the simulation (100ns max)
run 100ns
