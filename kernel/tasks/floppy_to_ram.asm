
menu_handle_floppy_ram:
    call clear_screen

    mov byte [head], 0
    mov byte [cylinder], 0
    mov byte [sector], 0
    mov byte [number_of_sectors], 0
    mov word [ram_address], 0
    mov word [ram_address + 2], 0
    mov word [error_code], 0

    ;; Get the floppy head
    mov si, HEAD_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [head], al
   
    call clear_current_row

    ; get the cylinder
    mov si, CYLINDER_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [cylinder], al

    call clear_current_row

    ; get the sector
    mov si, SECTOR_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [sector], al
 
    call clear_current_row

    ; get the number of sectors
    mov si, NUMBER_OF_SECTORS_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [number_of_sectors], al

    call clear_current_row

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

read_floppy_ram:
    ; Set up the RAM address to store the data
    mov bx, [ram_address]  ; RAM address to store the data
    mov es, bx  ; Set the segment register to the RAM address
    mov bx, [ram_address + 2]  ; Offset to the RAM address

    ; Set up the floppy disk parameters
    mov ah, 0x02  ; Read sector function
    mov al, byte [number_of_sectors]  ; Number of sectors to read
    mov ch, byte [cylinder]  ; Cylinder number
    mov cl, byte [sector] ; Sector number
    mov dh, byte [head]  ; Head number
    mov dl, byte [BOOT_DISK]  ; Drive number (0x00 for floppy disk)

    int 0x13  ; BIOS interrupt

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
    mov si, WAIT_FOR_ENTER_OR_SPACE_MSG
    call print_string
    jmp .print_data

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
        jmp stop_printing

    .print_data:
        pusha
        xor ax, ax
        xor bx, bx
        xor cx, cx
        xor dx, dx
        xor bp, bp
        mov word [cursor_coords], 0400H
        call sync_cursor

        ; print the data from the RAM address
        mov cx, 0
        mov es, [ram_address]
        mov bx, [ram_address + 2]
        xor dx, dx

        .loop_sectors:
            cmp cx, [number_of_sectors]
            je stop_printing

            xor dx, dx
            .loop_sector:
                cmp dx, 512
                je .loop_sectors_dec

                mov ah, 0eh
                mov al, [es:bx]
                int 10h

                inc bx
                inc dx
                jmp .loop_sector

            .loop_sectors_dec:
                mov byte [three], 3
                ; xor ax, ax
                inc cx
                mov ax, cx
                div byte [three]
                
                mov al, ah; convert ah to ax
                mov ah, 0
                mov [remainder], ax

                xor ax, ax
                mov es, [ram_address]
                cmp word [remainder], 0
                je .wait_space_press

                jmp .loop_sectors

        .wait_space_press:
            ; compare the key pressed to space or enter, do different things for each
            mov ah, 0
            int 16h
            cmp al, 0x0d
            je stop_printing
            cmp al, 0x20
            je .loop_sectors

            jmp .wait_space_press

        popa
        jmp stop_printing     

stop_printing:
    mov ax, 0x7e00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ax
    mov bp, ax 

    call wait_for_enter
    mov word [cursor_coords], 0000H
    jmp menu