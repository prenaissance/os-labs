BITS 16
ORG 7c00H
;; my sector: 91
;; CHS format: Cylinder: 2, Head: 1, Sector: 2

start:
    mov [BOOT_DISK], dl; save boot disk number

    call clear_screen
    mov bh, 0      
    mov ax, 0H
    mov es, ax
    mov si, WELCOME_MSG

    mov bl, 07H
    mov dx, 0100H
    call print_string

    mov si, PRESS_MSG
    mov dx, 0300H
    call print_string

    mov dh, 1       ; Set DH: boot 2 sectors
    mov dl, [BOOT_DISK]       ; set DL: boot from drive 0

kernel_load:
    ; setup es:bx to point to the sector to load to memory
    mov bx, 7e00H
    mov es, bx
    mov bx, 0x0000    

    mov dl, [BOOT_DISK] ; boot from boot drive
    mov ch, 0 ; cylinder
    mov dh, 0 ; head
    mov cl, 2 ; sector read after boot sector

    mov ah, 0x02 ; read disk function
    mov al, 0x03 ; number of sectors to read
    int 0x13     ; call interrupt 13h

    jc disk_error ; jump if carry flag is set

    mov ax, 0x7e00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ax

wait_for_enter:
    mov ah, 0
    int 16h

    cmp al, 0dh
    jz jump_to_kernel

    jmp wait_for_enter

jump_to_kernel:
    mov dl, [BOOT_DISK]
    jmp 0x7e00:0x0000

clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

disk_error:
    mov bh, 0                 
    mov ax, 0H
    mov es, ax                 
    mov bp, error_disk 

    mov bl, 07H                
    mov cx, 11                
    mov dh, 0                
    mov dl, 0       

    mov ax, 1301H
    int 10H

%include "utils/string/common.asm"

cursor_coords:
    cursor_x db 0
    cursor_y db 0
WELCOME_MSG dd "Andries Alexandru's lab4", 0
CYLINDER_MSG dd "Enter cylinder", 0
HEAD_MSG dd "Enter head", 0
SECTOR_MSG dd "Enter sector", 0
PRESS_MSG dd "Press ENTER to continue...", 0
error_disk dd "Disk Error!", 0
BOOT_DISK db 0

times 510 - ($-$$) db 0
dw 0xaa55