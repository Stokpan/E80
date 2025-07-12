; This program is for testing and showcasing various features of E80
; It calculates 179 div 13 =  14 into R0,
;               179 mod 13 =  11 into R1,
;                 7 mul 29 = 203 into R2.

.TITLE "Multiplication and division with subroutines (divmul.asm)"
.DATA 100 7,29			; multiplicand = [100] = 7, multiplier = [101] = 29
.NAME dividend 179
.NAME divisor 12

	CALL multiply		; R0 = 7×29 = 203
	PUSH R0
	CALL division		; R0 = 179 div 13 = 14, R1 = 179 mod 13 = 11
	POP R2
	HLT

division:				; "Ascend-descend" division algorithm by Panos Stokas
    MOV R1, dividend	; remainder (starts as dividend)
    MOV R2, divisor		; scaled divisor, goes up to dividend and back down
    MOV R0, 0			; quotient
    MOV R3, 1			; quotient bit, R3 * original divisor = R2
ascend:					; double divisor until ≥ dividend or 128
    CMP R2, R1
    JC descend			; if R2 ≥ R1
    BIT R2, 0b10000000
    JNZ descend			; no divisor ≥ 128 for 8 bits (also prevent overflow)
    LSHIFT R2			; scale divisor
    LSHIFT R3			; move quotient bit to the left
    JMP ascend
descend:				; subtract and halve divisor until we're back
    CMP R1, R2
    JNC halve_divisor	; if R2 > R1
    SUB R1, R2			; remainder -= scaled divisor
    OR R0, R3			; quotient += quotient bit
halve_divisor:
    RSHIFT R2			; halve scaled divisor
    RSHIFT R3			; move quotient bit to the right
    JZ division_done	; stop when the quotient bit is dropped
    JMP descend
division_done:
	RETURN

multiply:	    		; Russian Peasant multiplication algorithm
	LOAD R1, [100]		; multiplicand at memory address 100
	LOAD R2, [101]		; multiplier at memory address 101
	MOV R0, 0			; accumulated product
multiply_loop:
	BIT R2, 0xFF
	JZ multiply_done	; stop when multiplier = 0
	BIT R2, 1
	JZ skip_add			; even R2 ⇒ R1×R2 = (R1×2)×(R2 div 2) ⇒ skip add R1
	ADD R0, R1			; odd R2 ⇒ R1×R2 = (R1×2)×(R2 div 2)+R1 ⇒ add R1
skip_add:
	LSHIFT R1			; R1×2
	RSHIFT R2			; R2 div 2
	JMP multiply_loop
multiply_done:
	RETURN 