column_temp db 0

wait_for_enter:
    pusha
    .wait_for_enter_loop:
        mov ah, 0
        int 16h
        cmp al, ENTER
        jne .wait_for_enter_loop
    popa
    ret

wait_for_space:
    pusha
    mov ah, 0
    int 16h
    cmp al, SPACE
    jne wait_for_space
    popa
    ret

;; Syncs the cursor with the coordinates stored in cursor_coords
sync_cursor:
    pusha
    mov ah, 0x02
    mov bh, 0x00
    mov dx, [cursor_coords]
    int 0x10
    popa
    ret

;; Clears a row
;; Parameters: al: the row to clear
;; Returns: nothing
;; Mutates: the screen
clear_row:
    pusha
    mov byte [column_temp], dh
    ;; Get current cursor position
    mov ah, 0x03
    mov bh, 0
    int 0x10 ; cursor position is stored in dx
    push dx ; save cursor position
    ;; Set cursor position to the start of the row
    mov ah, 0x02
    mov bh, 0
    mov dl, 0
    mov dh, byte [column_temp]
    int 0x10
    ;; write a line of white space
    mov ah, 0AH; print the character at the cursor position
    mov bh, 0; page number
    mov cx, 80; number of times to print the character
    mov al, ' '; print a space
    int 10h
    ;; Restore cursor position
    pop dx
    mov ah, 0x02
    mov bh, 0
    int 0x10

    popa
    ret

;; Clears the current row and resets the cursor position to the start of the row
;; Parameters: none
;; Returns: nothing
;; Mutates: the screen
clear_current_row:
    pusha
    mov byte [cursor_x], 0
    call sync_cursor
    ;; write a line of white space
    mov ah, 0AH; print the character at the cursor position
    mov bh, 0; page number
    mov cx, 80; number of times to print the character
    mov al, ' '; print a space
    int 10h
    popa
    ret

;; Prompts input from the user
;; Parameters: si: the string to prompt the user with
;;             di: the buffer to store the user input
;;             global cursor_coords: the coordinates of the cursor to start the prompt at
;; Returns: nothing
;; Mutates: the buffer pointed to by di
;;          the cursor coordinates
;; Notes: maximum input length is 256 characters
prompt:
    pusha
    mov bh, 0; page number
    mov bl, 7; text color
    mov dx, word [cursor_coords]; get the cursor coordinates
    call print_string; print the prompt string

    call str_len; get the length of the prompt string
    mov byte [cursor_x], cl
    call sync_cursor; sync the cursor with the coordinates
    mov cx, 0; character counter
    .prompt_read_char:
        mov ah, 0
        int 16h

        cmp al, BACKSPACE; if the character is backspace
        je .prompt_handle_backspace; jump to handle_backspace
        cmp al, ENTER; if the character is enter
        je .prompt_handle_enter; jump to handle_enter
        jmp .prompt_handle_symbol; jump to handle_symbol

    .prompt_handle_symbol:
        cmp cx, MAX_CHARACTER_COUNT; if the character counter is equal to the maximum character count
        je .prompt_read_char

        mov [di], al; store the character in the buffer
        inc di; increment the buffer pointer
        inc cx; increment the character counter
        inc byte [cursor_x]; increment the cursor x coordinate
        pusha; save all registers
        mov ah, 0eh; print the character
        int 10h
        popa; restore all registers
        jmp .prompt_read_char; read another character

    .prompt_handle_backspace:
        cmp cx, 0; if the character counter is 0, do nothing
        je .prompt_read_char

        dec di; decrement the buffer pointer
        dec cx; decrement the character counter
        dec byte [cursor_x]; decrement the cursor x coordinate
        call sync_cursor;
        pusha; save all registers
        mov ah, 0AH; print the character at the cursor position
        mov bh, 0; page number
        mov cx, 1; number of times to print the character
        mov al, ' '; print a space
        int 10h
        popa; restore all registers
        jmp .prompt_read_char; read another character

    .prompt_handle_enter:
        ;; don't do anything if string length is 0
        cmp cx, 0
        je .prompt_read_char
        mov byte [di], 0; null terminate the string
        inc di; increment the buffer pointer
        popa
        ret