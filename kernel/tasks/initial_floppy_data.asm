SECTORS_PER_TRACK dw 18
HEADS dw 2
%define SECTOR_SIZE 512

%define MESSAGE_REPEAT_COUNT 10
%define SECTOR_BEGIN_ALEX 91
%define SECTOR_END_ALEX 120

%define SECTOR_BEGIN_TUDOR 661
%define SECTOR_END_TUDOR 690

%define SECTOR_BEGIN_CRISTINA 781
%define SECTOR_END_CRISTINA 810

;; Converts a linear sector number to a CHS address.
;; Parameters: ax = linear sector number
;; Returns:    cx (bits 0-5)  = sector
;;             cx (bits 6-15) = cylinder
;;             dh             = head
lba_to_chs:
    push ax
    push dx

    xor dx, dx; dx = 0
    div word [SECTORS_PER_TRACK]; ax = LBA / SectorsPerTrack
                                ; dx = LBA % SectorsPerTrack

    inc dx; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx ; cx = sector

    xor dx, dx; dx = 0
    div word [HEADS]; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                        ; dx = (LBA / SectorsPerTrack) % Heads = head
    mov dh, dl; dh = head
    mov ch, al; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al; restore DL
    pop ax
    ret

insert_initial_floppy_data:
    mov ah, 0
    int 13H
    ;; Make the input string
    mov cx, MESSAGE_REPEAT_COUNT
    mov si, ALEX_MESSAGE
    mov di, names_buffer
    call repeat_string
    ;;; Write the string to the floppy
    ;; convert LBA to CHS
    mov ax, SECTOR_BEGIN_ALEX
    call lba_to_chs
    ;; write the sector
    mov ah, 03H
    mov al, 01H
    mov bx, names_buffer
    mov dl, [BOOT_DISK]
    int 13H
    jc print_io_error
    ;; convert LBA to CHS
    mov ax, SECTOR_END_ALEX
    call lba_to_chs
    ;; write the sector
    mov ah, 03H
    mov al, 01H
    mov bx, names_buffer
    mov dl, [BOOT_DISK]
    int 13H
    jc print_io_error

    mov cx, MESSAGE_REPEAT_COUNT
    mov si, TUDOR_MESSAGE
    mov di, names_buffer
    call repeat_string
    ;;; Write the string to the floppy
    ;; convert LBA to CHS
    mov ax, SECTOR_BEGIN_TUDOR
    call lba_to_chs
    ;; write the sector
    mov ah, 03H
    mov al, 01H
    mov bx, names_buffer
    mov dl, [BOOT_DISK]
    int 13H
    jc print_io_error
    ;; convert LBA to CHS
    mov ax, SECTOR_END_TUDOR
    call lba_to_chs
    ;; write the sector
    mov ah, 03H
    mov al, 01H
    mov bx, names_buffer
    mov dl, [BOOT_DISK]
    int 13H
    jc print_io_error

    mov cx, MESSAGE_REPEAT_COUNT
    mov si, CRISTINA_MESSAGE
    mov di, names_buffer
    call repeat_string
    ;;; Write the string to the floppy
    ;; convert LBA to CHS
    mov ax, SECTOR_BEGIN_CRISTINA
    call lba_to_chs
    ;; write the sector
    mov ah, 03H
    mov al, 01H
    mov bx, names_buffer
    mov dl, [BOOT_DISK]
    int 13H
    jc print_io_error
    ;; convert LBA to CHS
    mov ax, SECTOR_END_CRISTINA
    call lba_to_chs
    ;; write the sector
    mov ah, 03H
    mov al, 01H
    mov bx, names_buffer
    mov dl, [BOOT_DISK]
    int 13H
    jc print_io_error

    ret

print_io_error:
    mov al, ah,
    mov ah, 0
    mov di, buffer
    call int_to_string
    mov si, buffer
    mov bh, 0
    mov bl, 0x0F
    mov dx, 0x0007
    call print_string
    jmp $