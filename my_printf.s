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
;>	LODSB	        |       MOV DS:[SI], AL
;>	STOSB           |       MOV AL, ES:[DI] + 
;                   |               INC/DEC DI (check DF)
;>	MOVSB           |       MOV DS:[SI], ES:[DI] + 
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
;  @brief: my_printf is a function that can be called from C program (check main.c), uses __cdecl
;  @uses:  RAX, R[8-9, 12-15], RDI, RSI, RDX, RSX, RSP, RBX, RBP
;  @ret:   NOTHING
;----------------------------------------------------------------
my_printf:
			CLD         ; clear DF
			POP    RAX	; ! SAVE RETURN ADDRESS !

			PUSH   R9	; 6th arg
			PUSH   R8	; 5th arg
			PUSH   RCX	; 4th arg
			PUSH   RDX	; 3rd arg
			PUSH   RSI	; 2nd arg
			PUSH   RDI	; 1st arg

			;> callee-saved registers, saving values
			PUSH   RSP
			PUSH   RBP
			PUSH   RBX	
			; R[12-15]
			PUSH   R12
			PUSH   R13	
			PUSH   R14	
			PUSH   R15	


			MOV    R15, RAX ; ! saving return address to R15
			MOV    RBP, RSP ; saving stack pointer to RBP, so it will be available

			ADD    RBP, (alignment * 7) ; shifting to our args, each arg takes 8 bytes
			CALL   _my_printf ; launching function

			MOV    RAX, R15 ; ! saving return address back to RAX

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
			MOV    RSI, [RBP] ; saving format string to parse
			MOV    RDI, buffer_out ; output will be stored here

empty:
			xor    RAX, RAX ; MOV RAX, 0

			CMP    byte [RSI], 0 ; if we found NULL-byte (end of c-style string)
			JE     end_printf ; printing out

			CMP    byte [RSI], '%' ; if we found format specifier 
			JNE    str_char
			INC    RSI

			CMP    byte [RSI],'%' ; if we found '%%', so we need to print '%'
			JE     str_char
			LODSB

			JMP   [JMP_TABLE + (RAX - 'b') * 8]

;=====================================================================
binary:;--------------------------------------------------------------
			ADD   RBP,8
			MOV   EAX,[RBP]
			MOV   ECX,binary_radix
			CALL  itoa
			JMP   empty

character:;-----------------------------------------------------------
			ADD   RBP,8
			MOV   EAX,[RBP]
			STOSB
			JMP empty

octal:;---------------------------------------------------------------
			ADD   RBP,8
			MOV   EAX,[RBP]
			MOV   ECX,octal_radix
			CALL  itoa
			JMP   empty

demical:;-------------------------------------------------------------
			ADD   RBP,8
			MOV   EAX,[RBP]
			MOV   ECX,digit_radix
			CALL  itoa
			JMP   empty

hexadecimal:;---------------------------------------------------------
			ADD   RBP,8
			MOV   EAX,[RBP]
			MOV   ECX,hex_r
			CALL  itoa
			JMP   empty

string:;--------------------------------------------------------------
			PUSH RSI
			ADD   RBP,8
			MOV   RSI,[RBP]
			CALL copyString
			POP RSI		
			JMP empty

str_char:;--------------------------------------------------------
			MOVSB
			JMP empty

end_printf:;----------------------------------------------------------------
			MOV   RSI,buffer_out
			MOV   RAX,std_out_syscall		; write syscall
			MOV   RDX,RDI                
			SUB   RDX,buffer_out		; strlen
			MOV   RDI,std_out_descriptor	; output descriptor
			SYSCALL
			RET

%include 'strlib.asm'

;=====================================================================
	section .bss
buffer_out: RESB max_len
;=====================================================================
	section .rodata
std_out_descriptor EQU 1  ; { system settings
std_out_syscall EQU 1     ; |
alignment EQU 8           ; }

binary_radix EQU 2        ; { bases for itoa function
octal_radix EQU 8         ; |
digit_radix EQU 10        ; |
hex_r EQU 16          ; }

max_len EQU 512           ; my_printf-len of buffer
;=====================================================================
	JMP_TABLE:
DQ binary
DQ character
DQ demical
times 10 DQ empty ;calculate ('o'-'d'-1)-distance
DQ octal
times 3 DQ empty  ;calculate ('s'-'o'-1)-distance
DQ string
times 4 DQ empty  ;calculate ('x'-'s'-1)-distance
DQ hexadecimal
;=====================================================================
;jump table allows you to execute the desired instruction, depending
;on what the program encounters as a specifier from the C language