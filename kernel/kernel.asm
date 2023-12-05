%define BACKSPACE 0x08
%define ENTER 0x0D
%define ESC 0x1B
%define SPACE 0x20
%define ARROW_UP_SCANCODE 0x48
%define ARROW_DOWN_SCANCODE 0x50
%define MAX_CHARACTER_COUNT 200

%define MENU_MESSAGES_COUNT 3

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

    ALEX_MESSAGE db "@@@FAF-211 Alex ANDRIES###@@@", 0
    TUDOR_MESSAGE db "@@@FAF-211 Tudor SCLIFOS###@@@", 0
    CRISTINA_MESSAGE db "@@@FAF-211 Cristina TARNA###@@@", 0
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
    ram_address resb 4
    three resb 2
    ram_buffer resb 512

section .text
    global main

main:
    mov [BOOT_DISK], dl
    call menu
    jmp $

clear_screen:
    mov ah, 0; set the video mode
    mov al, 3; 80x25 text mode
    int 10h
    ret

menu:
    call print_menu; print the menu
    .menu_read_char:
        mov ah, 0
        int 16h
    
    cmp ah, ARROW_UP_SCANCODE; if the character is arrow up
    je .menu_handle_arrow_up; jump to handle_arrow_up
    cmp ah, ARROW_DOWN_SCANCODE; if the character is arrow down
    je .menu_handle_arrow_down; jump to handle_arrow_down
    cmp al, ENTER; if the character is enter
    je .menu_handle_enter; jump to handle_enter
    jmp .menu_read_char; else jump to read_char

    .menu_handle_arrow_up:
        ;; decrement the menu selection and get the modulo of the menu selection and the number of messages
        dec byte [menu_selection]
        cmp byte [menu_selection], -1
        jne .menu_handle_arrow_up_not_overflow
        mov byte [menu_selection], MENU_MESSAGES_COUNT - 1
        .menu_handle_arrow_up_not_overflow:
        call print_menu; print the menu
        jmp .menu_read_char; read another character
    
    .menu_handle_arrow_down:
        ;; incremenet the menu selection and get the modulo of the menu selection and the number of messages
        inc byte [menu_selection]
        cmp byte [menu_selection], MENU_MESSAGES_COUNT
        jne .menu_handle_arrow_down_not_overflow
        mov byte [menu_selection], 0
        .menu_handle_arrow_down_not_overflow:
        call print_menu; print the menu
        jmp .menu_read_char; read another character
    
    .menu_handle_enter:
        ;; not yet implemented
        cmp byte [menu_selection], 0
        ; je keyboard_to_floppy
        cmp byte [menu_selection], 1
        ; je menu_handle_floppy_ram
        cmp byte [menu_selection], 2
        ; je ram_to_floppy
        jmp .menu_read_char; read another character

print_menu:
    call clear_screen
    mov cl, 0
    mov di, MENU_MESSAGES
    .print_menu_loop:
        cmp cl, MENU_MESSAGES_COUNT; if the message number is equal to the number of messages
        je .print_menu_end; jump to print_menu_end
        mov bh, 0; page numbers
        mov bl, 07H; text attribute
        mov dh, cl; row
        mov dl, 0; column
        cmp cl, [menu_selection]; if the message number is equal to the menu selection
        je .print_menu_selected; jump to print_selected
        jmp .print_menu_unselected; else jump to print_unselected
        .print_menu_selected:
            mov si, SELECTED_PREFIX
            jmp .print_menu_prefix
        .print_menu_unselected:
            mov si, UNSELECTED_PREFIX
        .print_menu_prefix:
            call print_string; print the prefix
        mov si, [di]; pointer to the message
        mov dl, 3; column
        call print_string; print the message
        add di, 2; increment the message pointer
        inc cl; increment the message number
        jmp .print_menu_loop; loop
    .print_menu_end:
        ret

%include "utils/string/common.asm"
%include "utils/conversion.asm"
%include "utils/io.asm"
; %include "lab3/utils/conversion.asm"