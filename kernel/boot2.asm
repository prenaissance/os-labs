;;; This is a second stage bootloader used to load the "kernel" because 512 bytes IS NOT ENOUGH
%define BACKSPACE 0x08
%define ENTER 0x0D
%define ESC 0x1B
%define SPACE 0x20
%define ARROW_UP_SCANCODE 0x48
%define ARROW_DOWN_SCANCODE 0x50
%define MAX_CHARACTER_COUNT 200
%define SECTOR_COPY_COUNT 6


section .data
    BOOT_DISK db 0
    cursor_coords:
        cursor_x db 0
        cursor_y db 0

    row db 0
    head db 0
    cylinder db 0
    sector db 0
    number dw 0
    sector_write_count dw 0
    number_of_sectors db 0
    error_code dw 0
    remainder dw 0
    qbytes dw 0

    FLOPPY_SUCCESS_MSG db "Floppy read/write success", 0
    FLOPPY_ERROR_MSG db "Floppy read/write error: ", 0
    TEXT_PROMPT db "Enter text: ", 0
    HEAD_PROMPT db "Enter head: ", 0
    CYLINDER_PROMPT db "Enter cylinder: ", 0
    SECTOR_PROMPT db "Enter sector: ", 0
    RAM_ADDRESS_PROMPT db "Enter RAM address: ", 0
    RAM_OFFSET_PROMPT db "Enter RAM offset: ", 0
    ARRAY_LENGTH_PROMPT db "Enter array length: ", 0
    ARRAY_ELEMENT_PROMPT db "Enter element: ", 0

    PRINT_ARRAY_MSG db "Array: ", 0
    RETURN_BOOTLOADER_MSG db "Press Enter to return to the bootloader", 0

    OPTION_ONE db "1. Enter kernel", 0
    OPTION_TWO db "2. Print array", 0
    ARRAY_SEPARATOR db ", ", 0
    ARRAY_BEGIN db "[", 0
    ARRAY_END db "]", 0

section .bss
    buffer resb 257
    array_buffer resw 16
    floppy_buffer resb 512
    conversion_buffer resb 32
    hex_conversion_buffer resb 64 
    ram_address:
        ram_address_value resw 1
        ram_offset resw 1
    three resb 2

section .text
    global main

main:
    ;; save boot disk
    mov byte [BOOT_DISK], dl
    .main_jmp:
    call clear_screen

    call prompt_chs
    call prompt_ram_address
    ;; test data
    ; mov byte [cylinder], 2
    ; mov byte [head], 1
    ; mov byte [sector], 2
    ; mov word [ram_address_value], 7F00H
    ; mov word [ram_offset], 7F00H
    call copy_kernel_to_ram
    call print_floppy_result
    call print_menu

    .read_option:
        mov ah, 0
        int 16H

        cmp al, '1'
        je handle_kernel

        cmp al, '2'
        je handle_sort

        jmp .read_option
    jmp $ ; will not reach here

clear_screen:
    mov ah, 0; set the video mode
    mov al, 3; 80x25 text mode
    int 10h
    ret

;; All the flow for querying CHS
;; Parameters: dx - the screen coordinates
prompt_chs:
    ; get the cylinder
    mov si, CYLINDER_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [cylinder], al

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

    ; get the sector
    mov si, SECTOR_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [sector], al

    call clear_current_row
    ret

prompt_ram_address:
    ; get the ram address
    mov si, RAM_ADDRESS_PROMPT
    mov di, hex_conversion_buffer
    call prompt
    ;; Convert the string to a hex
    mov si, hex_conversion_buffer
    mov di, ram_address_value
    call string_to_hex

    call clear_current_row

    ; get the offset address
    mov si, RAM_OFFSET_PROMPT
    mov di, hex_conversion_buffer
    call prompt
    ;; Convert the string to a hex
    mov si, hex_conversion_buffer
    mov di, ram_offset
    call string_to_hex

    call clear_current_row
    ret

print_menu:
    mov dx, 0000H
    mov si, OPTION_ONE
    call print_string
    mov dx, 0100H
    mov si, OPTION_TWO
    call print_string
    ret

handle_kernel:
    mov dl, [BOOT_DISK]
    mov ax, [ram_address_value]
    mov bx, [ram_offset]
    mov ds, bx
    mov es, bx
    mov ss, bx
    mov sp, bx
    jmp ax

handle_sort:
    call clear_screen
    mov si, ARRAY_LENGTH_PROMPT
    mov di, buffer
    call prompt
    mov si, di
    call string_to_int
    mov cx, ax
    push cx; store cx
    call clear_current_row
    mov bx, array_buffer

    .prompt_element_loop:
        mov si, ARRAY_ELEMENT_PROMPT
        mov di, buffer
        call prompt
        mov si, di
        call string_to_int
        mov [bx], ax
        add bx, 2
        call clear_current_row
    
    loop .prompt_element_loop

    mov bl, 0x0F
    mov si, PRINT_ARRAY_MSG
    call print_string_inline
    ;; restore array count
    pop cx
    push cx
    call print_array

    mov dx, 0400H
    mov bh, 0
    mov bl, 0x0F
    mov si, RETURN_BOOTLOADER_MSG
    call print_string

    .sort_wait_enter:
        mov ah, 0
        int 16h

        cmp al, ENTER
        je main.main_jmp
        jne .sort_wait_enter

;; Notes: the global variables with chs and ram address are used
copy_kernel_to_ram:
    ;; copy from floppy to ram
    ;; setup es:bx to point to the ram address
    mov dl, [BOOT_DISK]
    mov ch, [cylinder]
    mov dh, [head]
    mov cl, [sector]

    push es
    mov bx, [ram_address_value]
    mov ax, [ram_offset]
    mov es, ax

    mov ah, 0x02 ; read sectors code
    mov al, 6
    int 13h
    pop es
    ret

print_floppy_result:
    jc .pfr_error
    ;; print success message
    mov si, FLOPPY_SUCCESS_MSG
    mov dx, 0300H; cursor coordinates
    mov bl, 2; green color
    mov bh, 0
    call print_string
    jmp .pfr_end
    .pfr_error:
        mov si, FLOPPY_ERROR_MSG
        mov dx, 0300H; cursor coordinates
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
        mov dx, 0320H; cursor coordinates
        mov bh, 0
        call print_string
        jmp .pfr_end
    .pfr_end:
        mov bl, 0x0F; reset color
        ret

%include "utils/string/common.asm"
%include "utils/conversion.asm"
%include "utils/io.asm"
%include "utils/array.asm"