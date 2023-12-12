result dw 0

;; Converts string to uint
;; Parameters: si - string to convert
;; Returns:    ax - converted int
;;             bl - error code
string_to_int:
    pusha
    mov dx, si; save pointer to string
    mov ax, 0
    mov word [result], 0
    .string_to_int_loop:
        ;; check if null character is reached
        cmp byte [si], 0
        je .string_to_int_end
        ;; check if character is digit
        cmp byte [si], '0'
        jl .string_to_int_error
        cmp byte [si], '9'
        jg .string_to_int_error
        ;; convert character to int
        mov bx, 0
        mov bl, [si]
        sub bl, '0'
        ;; multiply current number by 10
        mov cx, 10
        mul cx
        ;; add current digit
        add ax, bx
        inc si
        jmp .string_to_int_loop
    .string_to_int_error:
        popa
        ; mov bl, 1 ; removed because of page problems
        mov ax, 0
        ret
    .string_to_int_end:
        mov [result], ax
        popa
        ; mov bl, 0 l removed because of page problems
        mov ax, [result]
        ret

;; Converts uint to string
;; Parameters: ax - uint to convert
;;             di - buffer to store string
;; Returns:    Nothing
;; Mutates:    di
int_to_string:
    pusha
    mov bx, 10
    mov cx, 0
    .int_to_string_loop:
        xor dx, dx
        div bx
        push dx
        inc cx
        cmp ax, 0
        jne .int_to_string_loop
    .int_to_string_loop2:
        pop dx
        add dl, '0'
        mov [di], dl
        inc di
        loop .int_to_string_loop2
    mov byte [di], 0
    popa
    ret


string_to_hex:
    atoh_conv_loop:
        cmp     byte [si], 0
        je      atoh_conv_done

        xor     ax, ax
        mov     al, [si]
        cmp     al, 65
        jl      conv_digit  

        conv_letter:
            sub     al, 55
            jmp     atoh_finish_iteration

        conv_digit:
            sub     al, 48

        atoh_finish_iteration:
            mov     bx, [di]
            imul    bx, 16
            add     bx, ax
            mov     [di], bx

            inc     si

        jmp     atoh_conv_loop

    atoh_conv_done:
        ret

hex_to_num:
    xor ax, ax          ; clear ax
    mov cx, 0           ; clear cx
    mov bl, [si]        ; get first character
    cmp bl, 0           ; check for null terminator
    je done             ; if null, we're done
    next_digit:
        shl ax, 4           ; shift left to make room for next digit
        cmp bl, '0'         ; check for digit
        jl done             ; if not a digit, we're done
        sub bl, '0'         ; convert to number
        cmp bl, 10          ; check for A-F
        jae upper_case      ; if >= A, convert to uppercase
        add al, bl          ; add to total
        jmp get_next        ; get next character
    upper_case:
        sub bl, 7           ; convert to uppercase
        add al, bl          ; add to total
    get_next:
        inc si              ; move to next character
        mov bl, [si]        ; get next character
        cmp bl, 0           ; check for null terminator
        jne next_digit      ; if not null, get next digit
    done:
        ret
