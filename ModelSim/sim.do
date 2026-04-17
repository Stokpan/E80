# E80 ModelSim simulation and layout automation script
# Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

# Stop previous simulation
quit -sim

# Open project and clear previous log 
project open e80.mpf
.main clear

# Compile all files, simulate (quietly = no log output)
quietly project compileall
vsim -quiet work.sim

# Switch to the project window and clear transcript window
quietly view project

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

add wave -noupdate -divider {Registers}
add wave -noupdate -radix unsigned /sim/R(0)
add wave -noupdate -radix unsigned /sim/R(1)
add wave -noupdate -radix unsigned /sim/R(2)
add wave -noupdate -radix unsigned /sim/R(3)
add wave -noupdate -radix unsigned /sim/R(4)
add wave -noupdate -radix unsigned /sim/R(5)
add wave -noupdate -label SP -radix unsigned /sim/R(7)

add wave -noupdate -divider {Stack region}
add wave -noupdate -radix unsigned /sim/RAM(251)
add wave -noupdate -radix unsigned /sim/RAM(252)
add wave -noupdate -radix unsigned /sim/RAM(253)
add wave -noupdate -radix unsigned /sim/RAM(254)
add wave -noupdate -radix hexadecimal /sim/RAM
add wave -noupdate /sim/DIPinput

# Format waves
configure wave -namecolwidth 104
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -rowmargin 4
configure wave -gridperiod 100
configure wave -timelineunits ps
quietly set PrefSource(OpenOnBreak) 0

# Stop simulation when the Halt flag is raised
when {/sim/Halt=='1'} {
	stop
	echo "Halt detected"
}

# Run the simulation (100ns max or until Halt)
quietly run 100ns

# Fine-tune zoom to fit 3 digits in a cycle and show waves
quietly wave zoom range 0 4400
quietly view wave

# Output the RAM content (32 columns) to the transcript window
echo "#      Final RAM Content"
echo "#      0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31"
echo "#      -----------------------------------------------------------------------------------------------"
mem display -dataradix hexadecimal -wo 32 /sim/RAM