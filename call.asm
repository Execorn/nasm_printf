global main

section .text
extern printf
main:   
            SUB RSP, 8
            MOV RDI, format_str
            MOV RSI, 55d

            XOR RAX, RAX 
            call printf


            RET


section .data

format_str: db "testing function, %i", 0xA, 0
