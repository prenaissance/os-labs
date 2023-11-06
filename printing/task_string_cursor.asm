BITS 16
ORG 0x7c00

start:
    mov ah, 0
    mov al, 0x03; clear screen
    int 0x10

    ; mov ax, 0x1301; print string
    ; mov bl, 0x09; light blue on black
    ; mov bh, 0x00; page 0
    ; mov cx, msg_len
    ; mov dx, [coords]
    ; mov bp, msg
    ; int 0x10

    ;; calculate msg len (1/2 of the array)
    mov cx, msg_attributes_double_len
    shr cx, 1

    ;; print attributes
    mov ax, 0x1303; print string
    mov bh, 0x00; page 0
    mov dx, [attributes_coords]
    mov bp, msg_attributes
    int 0x10

msg db "(25, 8) FAF-211 Andries Alexandru"
msg_len equ $-msg

msg_attributes db '(', 0x0F, '2', 0x01, '5', 0x02, ',', 0x03, ' ', 0x04, '1', 0x05, '0', 0x06, ')', 0x07, ' ', 0x08, 'A', 0x09, 'n', 0x0A, 'd', 0x0B, 'r', 0x0C, 'i', 0x0D, 'e', 0x0E, 's', 0x0F, ' ', 0x01, 'A', 0x02, 'l', 0x03, 'e', 0x04, 'x', 0x05, 'a', 0x06, 'n', 0x07, 'd', 0x08, 'r', 0x09, 'u', 0x0A
msg_attributes_double_len equ $-msg_attributes

coords:
coord_x db 25
coord_y db 8

attributes_coords:
attributes_coord_x db 25
attributes_coord_y db 10

times 510-($-$$) db 0
db 0x55, 0xAA
