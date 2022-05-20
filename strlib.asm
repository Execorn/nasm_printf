;   64-bit register | Lower 32 bits | Lower 16 bits | Lower 8 bits
;   ==============================================================
;   rax             | eax           | ax            | al
;   rbx             | ebx           | bx            | bl
;   rcx             | ecx           | cx            | cl
;   rdx             | edx           | dx            | dl
;   rsi             | esi           | si            | sil
;   rdi             | edi           | di            | dil
;   rbp             | ebp           | bp            | bpl
;   rsp             | esp           | sp            | spl
;>  r8              | r8d           | r8w           | r8b
;>  r9              | r9d           | r9w           | r9b
;>  r10             | r10d          | r10w          | r10b
;   r11             | r11d          | r11w          | r11b
;   r12             | r12d          | r12w          | r12b
;   r13             | r13d          | r13w          | r13b
;   r14             | r14d          | r14w          | r14b
;   r15             | r15d          | r15w          | r15b



;------------------------------------------------------------------------------
; ! COPY STRING FROM ES:[DI] to DS:[SI]
; ? ARGUMENTS:
; * 1) RSI - string pointer
; ! NOTHING GETS DESTROYED
;------------------------------------------------------------------------------
move_string:
            CMP   BYTE [RSI], 0 ; ? check for NULL-byte
            JE    .finish

            MOVSB               ; * MOV ES:[DI], DS:[SI] is where we actually copy
            JMP   move_string

.finish:
            RET

;------------------------------------------------------------------------------
; ! CONVERT INTEGER TO STRING
; ? ARGUMENTS:
; * 1) EAX - integer
; * 2) ECX - base
; * 3) RDI - string pointer (output buffer)
; ! EDX, R[8-10] GET DESTROYED
;------------------------------------------------------------------------------
universal_itoa:       
            ;> put zeros in registers
            XOR   EDX, EDX
            XOR   R8, R8
            XOR   R10, R10
            XOR   R9, R9
; ? Searches the source operand (second operand) for the least significant set bit (1 bit). 
; ? If a least significant 1 bit is found, its bit index is stored in the destination operand (first operand). 
; ? The source operand can be a register or a memory location; the destination operand is a register. 
            BSF   EDX, ECX ; ! SAVE least significant set bit in EDX
; ? Searches the source operand (second operand) for the most significant set bit (1 bit). 
; ? If a most significant 1 bit is found, its bit index is stored in the destination operand (first operand). 
; ? The source operand can be a register or a memory location; the destination operand is a register.          
            BSR   R8D, ECX ; ! SAVE most significant set bit in R8D
            ; * ECX is 32-bit register, but R8 is 64-bit

            JMP   .start_converting ; if least == most, then skip

.start_converting:
            INC   R9                         ; ? R9 - current string index

            XOR   EDX, EDX
            
            DIV   ECX                        ; ! divide EAX by ECX (base), put remainder in EDX  
                    
            MOV   R8b, [hex_alphabet + EDX]  ; EDX is a remainder of division
            MOV   [RDI], R8b                 ; put symbol in the string
            INC   RDI                        ; RDI now points to the next index

            CMP   EAX, 0                     ; if EAX == 0, reverse string and finish, we no longer need to convert 
            JNE   .start_converting

.reverse_result:
            PUSH RDI
            SUB RDI, R9 ; start string addr

            CALL buffer_fill_reversed
            POP RDI

            RET

buffer_fill_reversed:
            MOV R8, RDI  ; RDI - pointer to left side of string
            ADD R8, R9   ; R8  - pointer to right side of string, R9 is current index to copy

            DEC R8

.again:
            MOV R9B, [RDI]
            MOV R10B, [R8]

            MOV [RDI], R10B ; put it back in the memory
            MOV [R8],   R9B

            INC RDI
            DEC R8

            CMP RDI, R8
            JL .again ; if RDI < R8, do it again, string is not finished yet

            RET

section .rodata
hex_alphabet: db "0123456789ABCDEF" 