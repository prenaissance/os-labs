; Parameters: 
;             cx - element count
; Returns: Nothing
; Mutates: *array_buffer
bubble_sort:
    pusha
    dec cx
    mov bx, cx            ; Outer loop iteration count
    outer_loop:
        mov cx, bx            ; Inner loop iteration count
        mov si, array_buffer  ; Pointer to the start of the array
    inner_loop:
        mov dx, [si]          ; Current element
        mov ax, [si+2]        ; Next element
        cmp dx, ax
        jle no_swap
        xchg dx, ax           ; Swap elements
        mov [si], dx
        mov [si+2], ax
    no_swap:
        add si, 2             ; Move to the next pair of elements
        loop inner_loop       ; Continue until the inner loop is done
        loop outer_loop       ; Continue until the outer loop is done
    popa
    ret


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