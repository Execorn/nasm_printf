;--------------------------------------------------------------
; 	! CDECL EXPLANATION: !
; 
;	Register    |		Conventional use	
;   -----------------------------------------------------------
;>	RAX 		|		Return value, 	   caller-saved
;>	RDI			|		1st argument, 	   caller-saved	
;>	RSI			|		2nd argument, 	   caller-saved
;>	RDX			|		3rd argument, 	   caller-saved
;>	RCX			|		4th argument, 	   caller-saved
;>	R8			|		5th argument,      caller-saved
;>	R9			|		6th argument,      caller-saved	
;	            |
;	R10			|		Scratch/temporary, caller-saved
;	R11			|		Scratch/temporary, caller-saved	
;               |
;>	RSP			|		Stack pointer, 	   callee-saved	
;>	RBX			|		Local variable,    callee-saved
;>	RBP			|		Local variable,    callee-saved	
;>	R12			|		Local variable,    callee-saved	
;>	R13			|		Local variable,    callee-saved	
;>	R14			|		Local variable,    callee-saved
;>	R15			|		Local variable,    callee-saved	
;               |
;	%rip		|		Instruction pointer				
;	%rflags		|		Status/condition code bits	
;
; 	? ARGUMENTS ARE PASSED ACCORDING TO THIS TABLE ?
;--------------------------------------------------------------


;--------------------------------------------------------------
;	! FUNCTION TABLE !
;
;	Function		|		Purpose
;   -----------------------------------------------------------
;>	CLD             |       Clear DF (Direction Flag)
;>	LODSB	        |       MOV AL, DS:[SI]
;>	STOSB           |       MOV ES:[DI], AL + 
;                   |               INC/DEC DI (check DF)
;>	MOVSB           |       MOV ES:[DI], DS:[SI] + 
;                   |               INC/DEC (SI, DI) (check DF)
;   -----------------------------------------------------------
; 	
;   ! PSEUDO-INSTRUCTION TABLE !
;
;	Pseudo-instr.   |       Purpose
;	-----------------------------------------------------------
;	DB				|       _D_efine _B_yte (1 byte)
;	DW              |       _D_efine _W_ord (2 bytes)
;   DD              |       _D_efine _D_ouble Word (4 bytes)
;>	DQ              |       _D_efine _Q_uadword (8 bytes)
;	DDQ             |  	 	_D_efine _D_ouble _Q_uadword (16b.)
;>  TIMES           |	    Repeat instruction/data N times
;>  EQU             | 	    Define a symbol to constant value 
;>  RESB            |       Reserve N bytes (! not bits !)
;
;	? ALL USED FUNCTIONS/INSTRUCTIONS ARE EXPLAINED HERE ?
;--------------------------------------------------------------


global my_printf
section .text

;----------------------------------------------------------------
; ! Function my_printf that can be called from C program, using __cdecl.
; ! ARGUMENTS:
; ? R[9-15], RAX, RCX, RDX, RSI, RDI (look at table in the beginning of the file)
; ! NOTHING GETS DESTROYED
;----------------------------------------------------------------
my_printf:
			CLD         						; clear DF
			POP    RAX							; ! SAVE RETURN ADDRESS !

			PUSH   R9							; 6th arg
			PUSH   R8							; 5th arg
			PUSH   RCX							; 4th arg
			PUSH   RDX							; 3rd arg
			PUSH   RSI							; 2nd arg
			PUSH   RDI							; 1st arg

			;> callee-saved registers, saving values
			PUSH   RSP
			PUSH   RBP
			PUSH   RBX	
			; R[12-15]
			PUSH   R12
			PUSH   R13	
			PUSH   R14	
			PUSH   R15	


			MOV    R15, RAX 					; ! saving return address to R15
			MOV    RBP, RSP 					; saving stack pointer to RBP, so it will be available

			ADD    RBP, (alignment * 7) 		; shifting to our args, each arg takes 8 bytes
			CALL   _my_printf 					; launching function

			MOV    RAX, R15 					; ! saving return address back to RAX

			;> callee-saved registers, returning values 
			POP    R15	
			POP    R14	
			POP    R13
			POP    R12	
			POP    RBX	
			POP    RBP	
			POP    RSP

			;> caller-saved registers, returning parameters
			POP	   RDI	
			POP    RSI	
			POP    RDX	
			POP    RCX	
			POP    R8	
			POP    R9	

			PUSH   RAX  ; ! PUT RETURN ADDRESS BACK !
			RET         

_my_printf:
			MOV    RSI, [RBP] 					; saving format string to parse
			MOV    RDI, buffer_out 				; output will be stored here

next_char:
			XOR    RAX, RAX 					; MOV RAX, 0

			CMP    BYTE [RSI], 0 				; ! if we found NULL-BYTE (end of c-style string)
			JE     end_printf 					; printing out

			CMP    BYTE [RSI], '%'				; if we found format specifier 
			JNE    str_char
			INC    RSI

			CMP    BYTE [RSI], '%' 				; ? if we found '%%', so we need to print '%'
			JE     str_char
			LODSB                               ; * MOV AL, DS:[SI]

			; ! RAX contains current char (its ASCII-code), 'a' is a beginning of JMP_TABLE 
			JMP   [JUMP_TABLE + (RAX - 'a') * 8]

print_bin:
			ADD   RBP, 8
			MOV   EAX, [RBP]
			MOV   ECX, bin_base

			CALL  universal_itoa
			JMP   next_char

print_char:;
			ADD   RBP, 8
			MOV   EAX, [RBP]
			STOSB

			JMP   next_char

print_oct:
			ADD   RBP, 8
			MOV   EAX, [RBP]
			MOV   ECX, oct_base

			CALL  universal_itoa
			JMP   next_char

print_integer:	
			ADD   RBP, 8
			MOV   EAX, [RBP]

			MOV   R11D, EAX
			AND   R11D, 0x80000000	
			CMP   R11D, 0
			JNE   put_sign
back:
			MOV   ECX, int_base

			CALL  universal_itoa
			JMP   next_char

put_sign:
			MOV   [RDI], BYTE 0x2d                 ; put '-' in the string
            INC   RDI 

			NEG   EAX
			;DEC   EAX
			;NOT   EAX                              ; EAX = ~EAX
			JMP   back
print_hex:
			ADD   RBP, 8
			MOV   EAX, [RBP]
			MOV   ECX, hex_base

			CALL  universal_itoa
			JMP   next_char

print_string:
			PUSH  RSI
			ADD   RBP, 8
			MOV   RSI, [RBP]
			
			CALL  move_string
			POP   RSI		
			JMP   next_char

str_char:
			MOVSB	   		  	        ; ? MOV ES:[DI], DS:[SI]
			JMP   next_char

; ! Filling registers for SYSCALL ('write' SYSCALL)
end_printf:
			MOV   RSI, buffer_out		; ? pointer to string
			MOV   RAX, stdout_call		; ? number of syscall (this one writes)
			MOV   RDX, RDI                

			SUB   RDX, buffer_out		; ? length of string
			MOV   RDI, stdout_d	        ; ! where to output (we output to stdin)

			SYSCALL
			RET

%include 'strlib.asm'

			; ! Section .bss contains statistically allocated variables
			section .bss
buffer_out: RESB buffer_size

			section .rodata	
stdout_d    	EQU 1  			; standart output descriptor 
stdout_call 	EQU 1       	; syscall
alignment 		EQU 8         	; sizeof(arg)

; ! BASE LIST FOR SPECIFIERS (ITOA)
bin_base 		EQU 2        
oct_base 		EQU 8         
int_base 		EQU 10        
hex_base 		EQU 16          

buffer_size EQU 512
;=====================================================================
JUMP_TABLE: ; ? size of pointer - 8 bytes (DQ), so we shift to ('our symbol' - 'a') * 8
DQ next_char
DQ print_bin
DQ print_char
DQ print_integer
times 10 DQ next_char ; * from 'e' to 'n'
DQ print_oct
times 3 DQ next_char  ; * 'p', 'q', 'r'
DQ print_string
times 4 DQ next_char  ; * to 'x'
DQ print_hex
times 2 DQ next_char