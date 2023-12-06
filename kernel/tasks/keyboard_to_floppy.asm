%define REPETITIONS_MIN 1
%define REPETITIONS_MAX 30000

keyboard_to_floppy:
    call clear_screen
    ;; Get the text
    mov si, TEXT_PROMPT
    mov di, buffer
    call prompt
    call clear_screen
    ;; Print the text 2 lines below
    mov si, buffer
    mov bh, 0
    ;; Set blue color
    mov bl, 1
    mov dx, 0200H; cursor coordinates
    call print_string
    mov bl, 0x0F; reset color
    mov dx, 0

    call clear_current_row
    ;; Get the floppy head
    mov si, HEAD_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [head], al

    call clear_current_row
    ;; Get the floppy cylinder
    mov si, CYLINDER_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [cylinder], al

    call clear_current_row
    ;; Get the floppy sector
    mov si, SECTOR_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [sector], al

    .ktf_repetitions_prompt:
        call clear_current_row
        ;; Get the number of repetitions
        mov si, REPETITIONS_PROMPT
        mov di, conversion_buffer
        call prompt
        mov word [number], ax
        ; mov dx, 0x0400
        ; mov si, conversion_buffer
        ; mov bh, 0
        ; call print_string
        ;; Convert the string to a number
        mov si, conversion_buffer
        call string_to_int
        ;; Check if number is within range
        cmp ax, REPETITIONS_MIN
        jl .ktf_repetitions_prompt_fail
        cmp ax, REPETITIONS_MAX
        jg .ktf_repetitions_prompt_fail
        jmp .ktf_repetitions_prompt_end

        .ktf_repetitions_prompt_fail:
            ;; Print error message with red 1 line below
            mov si, REPETITIONS_BETWEEN_MSG
            mov dx, 0101H; cursor coordinates
            mov bl, 4; red color
            call print_string
            mov bl, 0x0F; reset color
            mov dx, 0; reset cursor coordinates
            jmp .ktf_repetitions_prompt
        
    .ktf_repetitions_prompt_end:
        mov [number], ax
        call clear_screen
    ;; generate the repeated string
    mov si, buffer
    mov di, floppy_buffer
    mov cx, [number]
    call repeat_string ;; this WILL do a huge buffer overflow
    ;; get the sector write count
    ;; count = ceil(str_len(floppy_buffer) / 512)
    mov si, floppy_buffer
    call str_len; cx = str_len(floppy_buffer)
    mov ax, cx
    mov bx, 512
    div bx; ax = str_len(floppy_buffer) / 512
    cmp dx, 0; dx = str_len(floppy_buffer) % 512
    jne .ktf_sector_write_count_inc
    jmp .ktf_sector_write_count_end
    .ktf_sector_write_count_inc:
        inc ax; ax = str_len(floppy_buffer) / 512 + 1
    .ktf_sector_write_count_end:
    mov [sector_write_count], ax
    ;; write the string to floppy
    mov ah, 3; write to floppy
    mov al, byte [sector_write_count]
    mov ch, byte [cylinder]
    mov cl, byte [sector]
    mov dl, byte [BOOT_DISK]
    mov dh, byte [head]
    mov bx, floppy_buffer
    int 13h

    cmp ah, 0
    jne .ktf_floppy_error
    ;; print success message
    mov si, FLOPPY_SUCCESS_MSG
    mov dx, 0000H; cursor coordinates
    mov bl, 2; green color
    mov bh, 0
    call print_string
    mov bl, 0x0F; reset color
    jmp .ktf_end

    .ktf_floppy_error:
        mov si, FLOPPY_ERROR_MSG
        mov dx, 0000H; cursor coordinates
        mov bl, 4; red color
        mov bh, 0
        call print_string
        mov bl, 0x0F; reset color
        ;; convert error code to string representation of number
        mov al, ah; convert ah to ax
        mov ah, 0
        mov di, conversion_buffer
        call int_to_string
        mov si, conversion_buffer
        mov dx, 0020H; cursor coordinates
        mov bh, 0
        call print_string
        jmp .ktf_end

    .ktf_end:
        mov dx, 0200H;
        mov si, WAIT_FOR_ENTER_MSG
        call print_string
        call wait_for_enter
        mov word [cursor_coords], 0000H
        jmp menu