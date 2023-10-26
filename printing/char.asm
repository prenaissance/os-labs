BITS 16
ORG 0x7c00

start:
    mov ah, 0x0E
    mov al, 'A'
    int 0x10

times 510-($-$$) db 0
db 0x55, 0xAA
