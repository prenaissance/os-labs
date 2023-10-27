BITS 16
ORG 0x7c00

msg dw "Hello, World!"
msg_len equ $-msg

start:
    mov ax, 0x1300; print string
    mov bl, 0x09; light blue on black
    mov bh, 0x00; page 0
    mov cx, msg_len
    mov dx, 0x0100; row 1, col 0
    mov bp, msg
    int 0x10
    jmp $


times 510-($-$$) db 0
db 0x55, 0xAA
