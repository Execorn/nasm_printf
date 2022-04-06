copyString:
    cmp   byte [rsi], 0
    je    .exit
    movsb
    jmp   copyString
.exit:
    ret

itoa:       
    xor   edx, edx
    xor   r8, r8
    xor   r10, r10
    xor   r9, r9 ; r9 - strlen

    bsf   edx, ecx 
    bsr   r8d, ecx
    cmp   edx, r8d ; if ecx has only one non-0 bit (binary logarithm)
    jne   .slow_convert
            
    push cx
    mov cx, r8w

.slow_convert:
    inc   r9

    xor   edx, edx
    div   ecx
            
    mov   r8, [hex_radix + edx]
    mov   [rdi], r8
    inc   rdi

    cmp   eax, 0
    jne   .slow_convert

.reverse:
    push rdi
    sub rdi, r9 ; start string addr
    call reverse_buf
    pop rdi

    ret

reverse_buf:
    mov r8, rdi ; rdi - left addr
    add r8, r9 ; r8 - rigth addr
    dec r8

.next_elem:
    mov r9b, [rdi]
    mov r10b, [r8]
    mov [rdi], r10b
    mov [r8], r9b

    inc rdi
    dec r8

    cmp rdi, r8
    jl .next_elem

    ret

section .rodata
hex_radix: db "0123456789ABCDEF"