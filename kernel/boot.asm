BITS 16
ORG 7c00H
;; my sector: 91
;; CHS format: Cylinder: 5, Head: 0, Sector: 2

start:
    mov [BOOT_DISK], dl; save boot disk number

    call clear_screen
    mov bh, 0                 
    mov ax, 0H
    mov es, ax                 
    mov bp, msg   

    mov bl, 07H                
    mov cx, 34               
    mov dh, 1    ; row             
    mov dl, 23    ; column 

    mov ax, 1301H
    int 10H 

    mov bh, 0                 
    mov ax, 0H
    mov es, ax                 
    mov bp, press   

    mov bl, 07H                
    mov cx, 24               
    mov dh, 15    ; row             
    mov dl, 28    ; column 

    mov ax, 1301H
    int 10H 

    mov al, 10      ; Load AL with the ASCII code for another newline character
    mov ah, 0eh     ; Set AH register to 0eh (subfunction: write character to the screen)
    int 10h         ; Call interrupt 10h

    mov al, 10      ; Load AL with the ASCII code for another newline character
    mov ah, 0eh     ; Set AH register to 0eh (subfunction: write character to the screen)
    int 10h         ; Call interrupt 10h

    mov al, 13      ; Load AL with the ASCII code for carriage return
    mov ah, 0eh     ; Set AH register to 0eh (subfunction: write character to the screen)
    int 10h         ; Call interrupt 10h

    mov dh, 1       ; Set DH: boot 2 sectors
    mov dl, [BOOT_DISK]       ; set DL: boot from drive 0

kernel_load:
    ; setup es:bx to point to the sector to load to memory
    mov bx, 0x7e00
    mov es, bx
    mov bx, 0x0000

    mov dl, [BOOT_DISK] ; boot from boot drive
    mov ch, 0x00 ; cylinder
    mov dh, 0x00 ; head
    mov cl, 0x02 ; sector read after boot sector

    mov ah, 0x02 ; read disk function
    mov al, 0x04 ; number of sectors to read
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

msg dd "------> Welcome <------", 10, 13, 0
press dd "Press ENTER to continue.", 10, 13, 0
error_disk dd "Disk Error!", 10, 13, 0
BOOT_DISK db 0

times 510 - ($-$$) db 0
dw 0xaa55