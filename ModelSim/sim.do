# Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

quit -sim
project open e80.mpf
wave zoom full
.main clear
quietly project compileall
vsim -quiet work.sim
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate /sim/CLK
add wave -radix unsigned /sim/PC
add wave -noupdate -radix hexadecimal /sim/Computer/Instr1
add wave -noupdate -radix hexadecimal /sim/Computer/Instr2
add wave -noupdate /sim/Computer/CPU/Carry
add wave -noupdate /sim/Computer/CPU/Zero
add wave -noupdate /sim/Computer/CPU/Sign
add wave -noupdate /sim/Computer/CPU/Overflow
add wave -noupdate /sim/Halt

add wave -noupdate -divider {Registers}
add wave -noupdate -radix unsigned /sim/R(0)
add wave -noupdate -radix unsigned /sim/R(1)
add wave -noupdate -radix unsigned /sim/R(2)
add wave -noupdate -radix unsigned /sim/R(3)
add wave -noupdate -radix unsigned /sim/R(4)
add wave -noupdate -radix unsigned /sim/R(5)
add wave -noupdate -label SP -radix unsigned /sim/R(7)

add wave -noupdate -divider {RAM/Input}
add wave -noupdate -radix unsigned /sim/Computer/RAM/RAM(251)
add wave -noupdate -radix unsigned /sim/Computer/RAM/RAM(252)
add wave -noupdate -radix unsigned /sim/Computer/RAM/RAM(253)
add wave -noupdate -radix unsigned /sim/Computer/RAM/RAM(254)
add wave -noupdate -radix hexadecimal /sim/Computer/RAM/RAM
add wave -noupdate /sim/DIPinput

TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 104
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -rowmargin 4
configure wave -gridperiod 100
configure wave -timelineunits ps
quietly set PrefSource(OpenOnBreak) 0

when {/sim/Halt=='1'} {
	stop
	echo "Halt detected"
}
run 100ns
add mem /sim/Computer/RAM/RAM -a hexadecimal -d symbolic -wo 16
# zoom is fine-tuned to fit 3 digits in a cycle
quietly wave zoom range 0 4400
quietly view wave