
pointer_store dw 0 ; used by str_len to avoid changing extra registers
pointer_store2 dw 0 ; used by str_equal to avoid changing extra registers

;; Gets string length
;; Parameters: si - pointer to string
;; Returns:    cx    - string length
;; Notes       String must be zero terminated
str_len:
    mov cx, 0
    mov [pointer_store], si
    cmp byte [si], 0
    je .str_len_end

    .str_len_loop:
        inc cx
        inc si
        cmp byte [si], 0
        jne .str_len_loop

    .str_len_end:
        mov si, [pointer_store]
        ret

;; Prints zero terminated string
;; Parameters: bh    - page number
;;             bl    - video attribute http://www.techhelpmanual.com/87-screen_attributes.html
;;             dh,dl - coords to start writing
;;             si - pointer to string
;; Returns:    None
print_string:
    pusha
    ;; Get string length
    call str_len
    mov ax, 1300h
    mov bp, si
    int 10h
    popa
    ret

;; Concatenate a string N times
;; Parameters: cx    - number of times to repeat
;;             si - pointer to input string
;;             di    - pointer to output string
;; Returns:    None
repeat_string:
    pusha
    ;; save pointer to input string
    mov [pointer_store], si
    .repeat_string_loop:
        mov si, [pointer_store]; restore pointer to input string each loop
        ;; copy input string to output string character by character
        ;; stop when null terminator is reached
        .repeat_string_copy_loop:
            mov al, [si]
            mov [di], al
            inc si
            inc di
            cmp byte [si], 0
            jne .repeat_string_copy_loop
    loop .repeat_string_loop
    mov byte [di], 0; add null terminator to output string

    popa
    ret

    ;; Concatenate a string N times
;; Parameters: cx    - number of bytes to copy
;;             es:bp - pointer to string from ram
;;             di    - pointer to output string
;; Returns:    None
get_string_from_ram:
    pusha
    .get_string_from_ram_loop:
        mov al, [es:bx]
        mov [di], al
        inc bx
        inc di
        loop .get_string_from_ram_loop
    mov byte [di], 0; add null terminator to output string

    popa
    ret