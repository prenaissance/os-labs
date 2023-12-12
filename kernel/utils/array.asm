;; Prints array
;; Parameters: cx - element count
;;             bh - page
;;             other video attributes idc
;; Returns: Nothing
;; Note: uses global *array_buffer and *conversion_buffer
print_array:
    pusha
    mov di, conversion_buffer
    mov dx, array_buffer ; used to span array
    mov si, ARRAY_BEGIN
    mov bl, 0x0F
    mov bh, 0
    call print_string_inline

    .print_array_loop:
        cmp cx, 0
        je .print_array_end
        mov ax, 0
        mov si, dx
        mov ax, [si]
        mov di, conversion_buffer
        call int_to_string
        mov si, di
        call print_string_inline
        dec cx
        add dx, 2
        cmp cx, 0
        je .print_array_end

    .print_separator:
        mov si, ARRAY_SEPARATOR
        call print_string_inline
        jmp .print_array_loop

    .print_array_end:
        mov si, ARRAY_END
        mov bl, 0x0F
        call print_string_inline
        popa
        ret