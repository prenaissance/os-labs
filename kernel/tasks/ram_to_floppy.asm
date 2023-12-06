; create a program in nasm to read from RAM, and write to floppy. the ram address {XXXX:YYYY}, will be inputed by the user, the {HEAD, TRACK, SECTOR} for the floppy will also be user inputted. The data block of "Q" bytes from RAM should be dislpayed on the screen. After compliting the disk writing operation, the error code should be displayed on the screen.

ram_to_floppy:
    call clear_screen

    mov byte [head], 0
    mov byte [cylinder], 0
    mov byte [sector], 0
    mov word [qbytes], 0
    mov word [ram_address], 0
    mov word [ram_address + 2], 0
    mov word [sector_write_count], 0
    mov byte [error_code], 0

    mov word [cursor_coords], 0000H
    call sync_cursor

    xor dx, dx

    ; print "Enter RAM address: "
    ; get the ram address
    mov si, RAM_ADDRESS_PROMPT
    mov di, hex_conversion_buffer
    call prompt
    ;; Convert the string to a hex
    mov si, hex_conversion_buffer
    mov di, ram_address
    call string_to_hex
  
    call clear_current_row

    ; get the offset address
    mov si, RAM_OFFSET_PROMPT
    mov di, hex_conversion_buffer
    call prompt
    ;; Convert the string to a hex
    mov si, hex_conversion_buffer
    mov di, ram_address + 2
    call string_to_hex

    call clear_current_row

    ; print "Enter floppy head: "
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

    call clear_current_row
    ;; Get the number of bytes to write "Q"
    mov si, BYTES_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov word [qbytes], ax

    call clear_current_row

write_from_ram_to_floppy:
    ;; Read from RAM
    ; Set up the RAM address to get the data
    mov es, [ram_address]  ; RAM address to store the data
    mov bx, [ram_address + 2] ; RAM offset to store the data

    ; Set up the floppy buffer
    mov di, ram_buffer
    mov cx, [qbytes] ; number of bytes to read
    call get_string_from_ram

    ; mov al, "L"
    ; mov ah, 0x0e
    ; int 10h

    ; mov ax, 0x7e00
    ; mov ds, ax
    ; mov es, ax
    ; mov ss, ax

    mov si, ram_buffer
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

        mov ax, 0x7e00
        mov es, ax
        ; write the string to floppy
        mov ah, 3h; write to floppy
        mov al, byte [sector_write_count]
        mov ch, byte [cylinder]
        mov cl, byte [sector]
        mov dl, byte [BOOT_DISK]
        mov dh, byte [head]
        mov bx, ram_buffer
        int 13h

        ;; check the error code
        cmp ah, 0
            mov al, ah; convert ah to ax
            mov ah, 0
            mov [error_code], ax

            mov ax, 0x7e00
            mov ds, ax
            mov es, ax
            mov ss, ax
            mov sp, ax
        jne .ktf_floppy_error

        ;; print success message
        mov si, FLOPPY_SUCCESS_MSG
        mov dx, 0000H; cursor coordinates
        mov bl, 2; green color
        mov bh, 0
        call print_string
        mov bl, 0x0F; reset color

        mov dx, 0200H;
        mov si, WAIT_FOR_ENTER_MSG
        call print_string
        jmp .end_rtf

        .ktf_floppy_error:
            
            mov si, FLOPPY_ERROR_MSG
            mov dx, 0000H; cursor coordinates
            mov bl, 4; red color
            mov bh, 0
            call print_string
            mov bl, 0x0F; reset color
            ;; convert error code to string representation of number
            mov ax, [error_code]
            mov di, conversion_buffer
            call int_to_string
            mov si, conversion_buffer
            mov dx, 0020H; cursor coordinates
            mov bh, 0
            call print_string

            mov dx, 0200H;
            mov si, WAIT_FOR_ENTER_MSG
            call print_string
            jmp .end_rtf

        .end_rtf:
            mov cx, [qbytes]
            mov dx, 0400h
            mov bl, 0x0f  
            mov si, ram_buffer
            call print_string
        call wait_for_enter
        mov word [cursor_coords], 0000H
        jmp menu

    