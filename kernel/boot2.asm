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
    SECTOR_SIZE dw 512
    menu_selection db 0

    SPACE_STR db " ", 0
    KEYBOARD_FLOPPY_MSG db "KEYBOARD ==> FLOPPY", 0
    FLOPPY_RAM_MSG db "FLOPPY ==> RAM", 0
    RAM_FLOPPY_MSG db "RAM ==> FLOPPY", 0
    SELECTED_PREFIX db "> ", 0
    UNSELECTED_PREFIX db "  ", 0
    MENU_MESSAGES dw KEYBOARD_FLOPPY_MSG, FLOPPY_RAM_MSG, RAM_FLOPPY_MSG
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
    REPETITIONS_PROMPT db "Enter number of repetitions: ", 0
    REPETITIONS_BETWEEN_MSG db "Number msut be between 1 and 30_000", 0
    WAIT_FOR_ENTER_MSG db "Press ENTER to continue", 0
    WAIT_FOR_ENTER_OR_SPACE_MSG db "Press ENTER to continue or SPACE to load more", 0
    NUMBER_OF_SECTORS_PROMPT db "Enter number of sectors: ", 0
    RAM_ADDRESS_PROMPT db "Enter RAM address: ", 0
    RAM_OFFSET_PROMPT db "Enter RAM offset: ", 0
    BYTES_PROMPT db "Enter bytes number: ", 0

section .bss
    buffer resb 257
    floppy_buffer resb 512
    names_buffer resb 512
    conversion_buffer resb 32
    hex_conversion_buffer resb 64 
    ram_address:
        ram_address_value resw 1
        ram_offset resw 1
    three resb 2
    ram_buffer resb 512

section .text
    global main

main:
    ;; save boot disk
    mov byte [BOOT_DISK], dl
    call clear_screen

    call prompt_chs
    call prompt_ram_address
    ;; test data
    mov byte [cylinder], 2
    mov byte [head], 1
    mov byte [sector], 2
    mov word [ram_address_value], 0x0000
    mov word [ram_offset], 07f0H
    jmp copy_kernel_to_ram

    jmp $ ; infinite loop

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

;; Notes: the global variables with chs and ram address are used
copy_kernel_to_ram:
    ;; copy from floppy to ram
    ;; setup es:bx to point to the ram address
    mov dl, [BOOT_DISK]
    mov ch, [cylinder]
    mov dh, [head]
    mov cl, [sector]

    mov bx, [ram_address_value]
    mov es, [ram_offset]

    mov al, SECTOR_COPY_COUNT
    mov ah, 0x02 ; read sectors
    int 13h

    ;; check for errors
    call print_floppy_result

    mov ds, [ram_offset]
    mov es, [ram_offset]
    mov ss, [ram_offset]
    mov sp, [ram_offset]

    mov dl, [BOOT_DISK]
    jmp 0

print_floppy_result:
    push es
    push bx
    mov bx, 07c0H
    mov es, bx
    jc .pfr_error
    ;; print success message
    mov si, FLOPPY_SUCCESS_MSG
    mov dx, 0200H; cursor coordinates
    mov bl, 2; green color
    mov bh, 0
    call print_string
    mov bl, 0x0F; reset color
    pop bx
    pop es
    ret
    .pfr_error:
        mov si, FLOPPY_ERROR_MSG
        mov dx, 0200H; cursor coordinates
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
        mov dx, 0220H; cursor coordinates
        mov bh, 0
        call print_string
        jmp $

%include "utils/string/common.asm"
%include "utils/conversion.asm"
%include "utils/io.asm"