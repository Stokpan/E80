# E80 Assembly grammar

The following context-free grammar was created as a blueprint for defining the E80 Assembly syntax. It was written in BNF format and thus it doesn't cover features such as comments and case-insensitivity. Still, a lot of its semantics match the internals of the E80ASM assembler.

To test it, [open it in Piber's testing suite](https://cpiber.github.io/CFG-Tester/#input=.TITLE%20%22test%22%0A%0A.SPEED%200%0A.DATA%20dat%2010%2C%20%22abc%22%2C%20100%0A%0A%09MOV%20R1%2C%2010%0Atest1%3A%0A%09LOAD%20R2%2C%20%5B0xFF%5D%0A%09CALL%20mult%0Amult%3A%20PUSH%20R1%09%09%09%09%0AJS%20100&rules=%3Cstart%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3C%5Bdirectives%5D%3E%20%3C%5Bstatements%5D%3E%20%3C%5Blabel%3A%5D%3E%0A%3C%5Bdirectives%5D%3E%20%20%3A%3A%3D%20%3Cdirective%3E%20%7C%20%3Cdirective%3E%20%3Cnl%2B%3E%20%3C%5Bdirectives%5D%3E%20%7C%20%3C%5B%5Cn%5D%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.TITLE%22%20%3Cs%2B%3E%20%3Cquoted_string%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.SPEED%22%20%3Cs%2B%3E%20%3Cdec%2B%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.SIMDIP%22%20%3Cs%2B%3E%20%3Cvalue%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.LABEL%22%20%3Cs%2B%3E%20%3Clabel%3E%20%3Cs%2B%3E%20%3Cnumber%3E%0A%3Cdirective%3E%20%20%20%20%20%3A%3A%3D%20%22.DATA%22%20%3Cs%2B%3E%20%3Clabel%3E%20%3Cs%2B%3E%20%3Carray%3E%0A%3C%5Bstatements%5D%3E%20%20%3A%3A%3D%20%3Cstatement%3E%20%7C%20%3Cstatement%3E%20%3Cnl%2B%3E%20%3C%5Bstatements%5D%3E%20%7C%20%3C%5B%5Cn%5D%3E%0A%3Cstatement%3E%20%20%20%20%20%3A%3A%3D%20%3Cinstruction%3E%20%7C%20%3Clabel%3A%3E%20%3Cinstruction%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_noarg%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_reg%3E%20%3Cs%2B%3E%20%3Creg%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_val%3E%20%3Cs%2B%3E%20%3Cvalue%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_reg_op2%3E%20%3Cs%2B%3E%20%3Creg%3E%20%3C%2C%3E%20%3Cop2%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_ldst%3E%20%3Cs%2B%3E%20%3Creg%3E%20%3C%2C%3E%20%3Cbracket_op2%3E%0A%3Cinstruction%3E%20%20%20%3A%3A%3D%20%3Cinstr_reg_n%3E%20%3Cs%2B%3E%20%3Creg%3E%20%3C%2C%3E%20%3Cvalue%3E%0A%3Cinstr_noarg%3E%20%20%20%3A%3A%3D%20%22HLT%22%20%7C%20%22NOP%22%20%7C%20%22RETURN%22%0A%3Cinstr_reg%3E%20%20%20%20%20%3A%3A%3D%20%22RSHIFT%22%20%7C%20%22LSHIFT%22%20%7C%20%22PUSH%22%20%7C%20%22POP%22%0A%3Cinstr_val%3E%20%20%20%20%20%3A%3A%3D%20%22JMP%22%20%7C%20%22JC%22%20%7C%20%22JNC%22%20%7C%20%22JZ%22%20%7C%20%22JNZ%22%20%7C%20%22JS%22%20%7C%20%22JNS%22%20%7C%20%22JV%22%20%7C%20%22JNV%22%20%7C%20%22CALL%22%0A%3Cinstr_reg_op2%3E%20%3A%3A%3D%20%22MOV%22%20%7C%20%22ADD%22%20%7C%20%22ROR%22%20%7C%20%22SUB%22%20%7C%20%22CMP%22%20%7C%20%22AND%22%20%7C%20%22OR%22%20%7C%20%22XOR%22%0A%3Cinstr_ldst%3E%20%20%20%20%3A%3A%3D%20%22LOAD%22%20%7C%20%22STORE%22%0A%3Cinstr_reg_n%3E%20%20%20%3A%3A%3D%20%22BIT%22%0A%3Cbracket_op2%3E%20%20%20%3A%3A%3D%20%22%5B%22%20%3Cop2%3E%20%22%5D%22%0A%3Cop2%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Creg%3E%20%7C%20%3Cvalue%3E%0A%3Cvalue%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cnumber%3E%20%7C%20%3Clabel%3E%0A%3C%5Blabel%3A%5D%3E%20%20%20%20%20%20%3A%3A%3D%20%3Clabel%3A%3E%20%7C%20%3C%5B%5Cn%5D%3E%0A%3Clabel%3A%3E%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Clabel%3E%22%3A%22%20%3C%5B%5Cn%5D%3E%0A%3Clabel%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cletter%3E%20%3Clabel_char%2A%3E%0A%3Clabel_char%2A%3E%20%20%20%3A%3A%3D%20%3Clabel_char%3E%20%3Clabel_char%2A%3E%20%7C%20%22%22%0A%3Clabel_char%3E%20%20%20%20%3A%3A%3D%20%3Cletter%3E%20%7C%20%3Cdec%3E%20%7C%20%22_%22%0A%3Creg%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%22R0%22%20%7C%20%22R1%22%20%7C%20%22R2%22%20%7C%20%22R3%22%20%7C%20%22R4%22%20%7C%20%22R5%22%20%7C%20%22R6%22%20%7C%20%22R7%22%20%7C%20%22FLAGS%22%20%7C%20%22SP%22%0A%3Carray%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Carray_element%3E%20%7C%20%3Carray_element%3E%20%3C%2C%3E%20%3Carray%3E%0A%3Carray_element%3E%20%3A%3A%3D%20%3Cnumber%3E%20%7C%20%3Cquoted_string%3E%0A%3Cquoted_string%3E%20%3A%3A%3D%20%22%5C%22%22%20%3Cchar%2B%3E%20%22%5C%22%22%0A%3C%2C%3E%20%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cs%2A%3E%20%22%2C%22%20%3Cs%2A%3E%0A%3Cnumber%3E%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cunumber%3E%20%7C%20%22-%22%20%3Cunumber%3E%0A%3Cunumber%3E%20%20%20%20%20%20%20%3A%3A%3D%20%220x%22%20%3Chex%2B%3E%20%7C%20%220b%22%20%3Cbit%2B%3E%20%7C%20%3Cdec%2B%3E%0A%3Chex%2B%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Chex%3E%20%7C%20%3Chex%3E%20%3Chex%2B%3E%0A%3Cdec%2B%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cdec%3E%20%7C%20%3Cdec%3E%20%3Cdec%2B%3E%0A%3Cbit%2B%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cbit%3E%20%7C%20%3Cbit%3E%20%3Cbit%2B%3E%0A%3Chex%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cdec%3E%20%7C%20%22A%22%20%7C%20%22B%22%20%7C%20%22C%22%20%7C%20%22D%22%20%7C%20%22E%22%20%7C%20%22F%22%20%7C%20%22a%22%20%7C%20%22b%22%20%7C%20%22c%22%20%7C%20%22d%22%20%7C%20%22e%22%20%7C%20%22f%22%0A%3Cdec%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%220%22%20%7C%20%221%22%20%7C%20%222%22%20%7C%20%223%22%20%7C%20%224%22%20%7C%20%225%22%20%7C%20%226%22%20%7C%20%227%22%20%7C%20%228%22%20%7C%20%229%22%0A%3Cbit%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%220%22%20%7C%20%221%22%0A%3Cchar%2B%3E%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cchar%3E%20%7C%20%3Cchar%3E%20%3Cchar%2B%3E%0A%3Cchar%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cletter%3E%20%7C%20%3Cdec%3E%20%7C%20%22%20%22%0A%3C%5B%5Cn%5D%3E%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cnl%2B%3E%20%7C%20%3Cs%2A%3E%0A%3Cnl%2B%3E%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cnl%3E%20%7C%20%3Cnl%3E%20%3Cnl%2B%3E%0A%3Cnl%3E%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cs%2A%3E%20%22%5Cn%22%20%3Cs%2A%3E%0A%3Cs%2A%3E%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cs%2B%3E%20%7C%20%22%22%0A%3Cs%2B%3E%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%3Cs%3E%20%7C%20%3Cs%3E%20%3Cs%2B%3E%0A%3Cs%3E%20%20%20%20%20%20%20%20%20%20%20%20%20%3A%3A%3D%20%22%20%22%20%7C%20%22%5Ct%22%0A%3Cletter%3E%20%20%20%20%20%20%20%20%3A%3A%3D%20%22A%22%20%7C%20%22B%22%20%7C%20%22C%22%20%7C%20%22D%22%20%7C%20%22E%22%20%7C%20%22F%22%20%7C%20%22G%22%20%7C%20%22H%22%20%7C%20%22I%22%20%7C%20%22J%22%20%7C%20%22K%22%20%7C%20%22L%22%20%7C%20%22M%22%20%7C%20%22N%22%20%7C%20%22O%22%20%7C%20%22P%22%20%7C%20%22Q%22%20%7C%20%22R%22%20%7C%20%22S%22%20%7C%20%22T%22%20%7C%20%22U%22%20%7C%20%22V%22%20%7C%20%22W%22%20%7C%20%22X%22%20%7C%20%22Y%22%20%7C%20%22Z%22%20%7C%20%22a%22%20%7C%20%22b%22%20%7C%20%22c%22%20%7C%20%22d%22%20%7C%20%22e%22%20%7C%20%22f%22%20%7C%20%22g%22%20%7C%20%22h%22%20%7C%20%22i%22%20%7C%20%22j%22%20%7C%20%22k%22%20%7C%20%22l%22%20%7C%20%22m%22%20%7C%20%22n%22%20%7C%20%22o%22%20%7C%20%22p%22%20%7C%20%22q%22%20%7C%20%22r%22%20%7C%20%22s%22%20%7C%20%22t%22%20%7C%20%22u%22%20%7C%20%22v%22%20%7C%20%22w%22%20%7C%20%22x%22%20%7C%20%22y%22%20%7C%20%22z%22), click on the cogwheel on the top right and select BNF.

```
<start>         ::= <[directives]> <[statements]> <[label:]>
<[directives]>  ::= <directive> | <directive> <nl+> <[directives]> | <[\n]>
<directive>     ::= ".TITLE" <s+> <quoted_string>
<directive>     ::= ".SPEED" <s+> <dec+>
<directive>     ::= ".SIMDIP" <s+> <value>
<directive>     ::= ".LABEL" <s+> <label> <s+> <number>
<directive>     ::= ".DATA" <s+> <label> <s+> <array>
<[statements]>  ::= <statement> | <statement> <nl+> <[statements]> | <[\n]>
<statement>     ::= <instruction> | <label:> <instruction>
<instruction>   ::= <instr_noarg>
<instruction>   ::= <instr_reg> <s+> <reg>
<instruction>   ::= <instr_val> <s+> <value>
<instruction>   ::= <instr_reg_op2> <s+> <reg> <,> <op2>
<instruction>   ::= <instr_ldst> <s+> <reg> <,> <bracket_op2>
<instruction>   ::= <instr_reg_n> <s+> <reg> <,> <value>
<instr_noarg>   ::= "HLT" | "NOP" | "RETURN"
<instr_reg>     ::= "RSHIFT" | "LSHIFT" | "PUSH" | "POP"
<instr_val>     ::= "JMP" | "JC" | "JNC" | "JZ" | "JNZ" | "JS" | "JNS" | "JV" | "JNV" | "CALL"
<instr_reg_op2> ::= "MOV" | "ADD" | "ROR" | "SUB" | "CMP" | "AND" | "OR" | "XOR"
<instr_ldst>    ::= "LOAD" | "STORE"
<instr_reg_n>   ::= "BIT"
<bracket_op2>   ::= "[" <op2> "]"
<op2>           ::= <reg> | <value>
<value>         ::= <number> | <label>
<[label:]>      ::= <label:> | <[\n]>
<label:>        ::= <label>":" <[\n]>
<label>         ::= <letter> <label_char*>
<label_char*>   ::= <label_char> <label_char*> | ""
<label_char>    ::= <letter> | <dec> | "_"
<reg>           ::= "R0" | "R1" | "R2" | "R3" | "R4" | "R5" | "R6" | "R7" | "FLAGS" | "SP"
<array>         ::= <array_element> | <array_element> <,> <array>
<array_element> ::= <number> | <quoted_string>
<quoted_string> ::= "\"" <char+> "\""
<,>             ::= <s*> "," <s*>
<number>        ::= <unumber> | "-" <unumber>
<unumber>       ::= "0x" <hex+> | "0b" <bit+> | <dec+>
<hex+>          ::= <hex> | <hex> <hex+>
<dec+>          ::= <dec> | <dec> <dec+>
<bit+>          ::= <bit> | <bit> <bit+>
<hex>           ::= <dec> | "A" | "B" | "C" | "D" | "E" | "F" | "a" | "b" | "c" | "d" | "e" | "f"
<dec>           ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
<bit>           ::= "0" | "1"
<char+>         ::= <char> | <char> <char+>
<char>          ::= <letter> | <dec> | " "
<[\n]>          ::= <nl+> | <s*>
<nl+>           ::= <nl> | <nl> <nl+>
<nl>            ::= <s*> "\n" <s*>
<s*>            ::= <s+> | ""
<s+>            ::= <s> | <s> <s+>
<s>             ::= " " | "\t"
<letter>        ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
```