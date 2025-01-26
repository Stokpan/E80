.TITLE "Uppercase"
.DATA string "`az{\"0",0    ; written after the last instruction (see under HLT)
    MOV R0, string          ; R0 = address of the first character ("`")
loop:   
    LOAD R1, [R0]           ; R1 = ANSI value of current character
    CMP R1, 0               ; if R1 = 0 (terminal)
    JZ finish               ;   goto finish.
    CMP R1, 97              ; else if R1-97
    JNC next                ;   is < 0 (thus R1 < 97), goto next.
    CMP R1, 123             ; else if R1 - 123
    JC next                 ;   is ≥ 0 (thus R1 > 122), goto next.
    SUB R1, 32              ; else, R1 ← R1 - 32 (change to uppercase)
    STORE R1, [R0]          ; write character back to RAM
next:
    ADD R0, 1               ; advance to the next memory address
    JMP loop                ; repeat loop
finish:
    HLT                     ; stop execution & simulation
string:                     ; label of the memory address after HLT