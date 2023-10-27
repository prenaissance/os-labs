BITS 16
ORG 0x7c00

msg_pairs dw 'H', 0x0A, 'I', 0x0B

start:
    mov ax, 0x1302; print chars with attributes and move cursor
    mov bh, 0; page number
    mov dl, 0; column
    mov dh, 1; row
    mov al, 1; default attribute
    mov bl, 7; default background
    mov bp, msg_pairs; pointer to pairs1
    mov cx, 2; number of pairs
    int 0x10

times 510-($-$$) db 0
db 0x55, 0xAA

