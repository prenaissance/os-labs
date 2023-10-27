BITS 16
ORG 0x7c00

start:
    mov ah, 0x09
    mov al, 'A'
    mov bl, 9; purple color
    mov cx, 2; 2 times
    int 0x10

times 510-($-$$) db 0
db 0x55, 0xAA
