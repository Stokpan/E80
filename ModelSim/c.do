# Copyright (C) 2026 Panos Stokas <panos.stokas@hotmail.com>

quit -sim
project open e80.mpf
wave zoom full
.main clear
quietly project compileall
vsim -quiet work.computer_tb
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate /computer_tb/CLK
add wave -radix unsigned /computer_tb/PC
add wave -noupdate -radix hexadecimal /computer_tb/Computer/Instr1
add wave -noupdate -radix hexadecimal /computer_tb/Computer/Instr2
add wave -noupdate /computer_tb/Computer/CPU/Carry
add wave -noupdate /computer_tb/Computer/CPU/Zero
add wave -noupdate /computer_tb/Computer/CPU/Sign
add wave -noupdate /computer_tb/Computer/CPU/Overflow
add wave -noupdate /computer_tb/Halt

add wave -noupdate -divider {Registers}
add wave -noupdate -radix unsigned /computer_tb/R(0)
add wave -noupdate -radix unsigned /computer_tb/R(1)
add wave -noupdate -radix unsigned /computer_tb/R(2)
add wave -noupdate -radix unsigned /computer_tb/R(3)
add wave -noupdate -radix unsigned /computer_tb/R(4)
add wave -noupdate -radix unsigned /computer_tb/R(5)
add wave -noupdate -label SP -radix unsigned /computer_tb/R(7)

add wave -noupdate -divider {RAM/Input}
add wave -noupdate -radix unsigned /computer_tb/Computer/RAM/RAM(251)
add wave -noupdate -radix unsigned /computer_tb/Computer/RAM/RAM(252)
add wave -noupdate -radix unsigned /computer_tb/Computer/RAM/RAM(253)
add wave -noupdate -radix unsigned /computer_tb/Computer/RAM/RAM(254)
add wave -noupdate -radix hexadecimal /computer_tb/Computer/RAM/RAM
add wave -noupdate /computer_tb/DIPinput

TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 104
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -rowmargin 4
configure wave -gridperiod 100
configure wave -timelineunits ps
quietly set PrefSource(OpenOnBreak) 0

when {/computer_tb/Halt=='1'} {
	stop
	echo "Halt detected"
}
run 100ns
add mem /computer_tb/Computer/RAM/RAM -a hexadecimal -d symbolic -wo 16
# zoom is fine-tuned to fit 3 digits in a cycle
quietly wave zoom range 0 4400
quietly view wave