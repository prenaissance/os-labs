;; Checks if 2 strings are equal
;; Parameters: si - pointer to string 1
;;             di    - pointer to string 2
;; Returns:    zf    - 1 if strings are equal, 0 otherwise
str_equal:
    pusha
    mov [pointer_store], si
    mov [pointer_store2], di
    .str_equal_loop:
        mov al, [si]
        mov ah, [di]
        cmp al, ah
        jne .str_equal_end
        cmp al, 0
        je .str_equal_end
        inc si
        inc di
        jmp .str_equal_loop
    .str_equal_end:
        mov si, [pointer_store]
        mov di, [pointer_store2]
        popa
        ret
