; minimal program to test the FPGA implementation and joystick control
.SIMDIP 0b00000010
	LOAD R0, [0xFF]
	MOV R1, 0
loop:
	ROR R0, 1
	ADD R1, 1
	JNC loop ; stop after 256 iterations
	HLT