BITS 16
ORG 0x7c00

start:
    mov al, 'A'
_loop:
    mov ah, 0x0E
    int 0x10
    inc al
    cmp al, 'Z' + 1
    jne _loop

times 510-($-$$) db 0
db 0x55, 0xAA
