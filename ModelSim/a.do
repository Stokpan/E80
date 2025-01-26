quit -sim
wave zoom full
.main clear
vsim work.alu_tb -quiet
onerror {resume}

quietly WaveActivateNextPane {} 0
add wave -noupdate -radix binary /alu_tb/FlagsIn
add wave -noupdate -label {ALUinA (binary)} -radix binary /alu_tb/ALUinA
add wave -noupdate -label {ALUinA (unsigned)} -radix unsigned /alu_tb/ALUinA
add wave -noupdate -label {ALUinA (signed)} -radix decimal /alu_tb/ALUinA
add wave -noupdate -label {ALUinB (binary)} -radix binary /alu_tb/ALUinB
add wave -noupdate -label {ALUinB (unsigned)} -radix unsigned /alu_tb/ALUinB
add wave -noupdate -label {ALUinB (signed)} -radix decimal /alu_tb/ALUinB
add wave -noupdate /alu_tb/ALUop
add wave -noupdate -label {ALUout (binary)} -radix binary /alu_tb/ALUout
add wave -noupdate -label {ALUout (unsigned)} -radix unsigned /alu_tb/ALUout
add wave -noupdate -label {ALUout (signed)} -radix decimal /alu_tb/ALUout
add wave -noupdate -label Carry /alu_tb/FlagsOut(7)
add wave -noupdate -label Zero /alu_tb/FlagsOut(6)
add wave -noupdate -label Sign /alu_tb/FlagsOut(5)
add wave -noupdate -label Overflow /alu_tb/FlagsOut(4)

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 137
configure wave -valuecolwidth 56
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps

run 800
wave zoom full