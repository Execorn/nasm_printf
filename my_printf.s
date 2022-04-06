
section .text
global my_printf

;=====================================================================
;   @brief: extern my_printf-function [can be called from c-program].
;     @use: {[a-d]x, r[9-15], [s-d]i, [b-s]p} 
; @destroy: 
;=====================================================================
my_printf:; my_printf message with specifiers
	cld
	POP    RAX	; remove return adress from stack

	PUSH   R9	; { six args
	PUSH   R8	; |
	PUSH   RCX	; |
	PUSH   RDX	; |
	PUSH   RSI	; |
	PUSH   RDI	; }

	PUSH   RSP	; { callee-used
	PUSH   RBP	; |
	PUSH   RBX	; |
	PUSH   R12	; |
	PUSH   R13	; |
	PUSH   R14	; |
	PUSH   R15	; }
			
	MOV    R15,RAX
	MOV    RBP,RSP
	ADD    RBP,(7 * reg_scale); points to args
	CALL   _my_printf

	MOV    RAX,R15 
	POP    R15	; { callee-used
	POP    R14	; |
	POP    R13	; |
	POP    R12	; |
	POP    RBX	; |
	POP    RBP	; |
	POP    RSP	; }

	POP    RDI	; { callee-used
	POP    RSI	; |
	POP    RDX	; |
	POP    RCX	; |
	POP    R8	; |
	POP    R9	; }

	PUSH   RAX
	RET         

_my_printf:
	MOV RSI, [RBP]              ; parsing string addr
	MOV RDI, output_string       ; buffer addr

empty:;---------------------------------------------------------------
	xor RAX, RAX
	CMP   byte [RSI],0
	JE  return

	CMP   byte [RSI],'%'
	JNE   str_char
	INC   RSI

	CMP   byte [RSI],'%'         ; %% case
	JE  str_char
	lodsb

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
	stosb
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
	movsb
	JMP empty

return:;----------------------------------------------------------------
	MOV   RSI,output_string
	MOV   RAX,std_out_syscall		; write syscall
	MOV   RDX,RDI                
	sub   RDX,output_string		; strlen
	MOV   RDI,std_out_descriptor	; output descriptor
	syscall
	RET

%include 'strlib.asm'

;=====================================================================
	section .bss
output_string: resb max_len
;=====================================================================
	section .rodata
std_out_descriptor equ 1  ; { system settings
std_out_syscall equ 1     ; |
reg_scale equ 8           ; }

binary_radix equ 2        ; { bases for itoa function
octal_radix equ 8         ; |
digit_radix equ 10        ; |
hex_r equ 16          ; }

max_len equ 512           ; my_printf-len of buffer
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