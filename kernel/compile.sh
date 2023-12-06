#!/bin/bash

boot="boot.asm"
bootloader="boot2.asm"
kernel="kernel.asm"

boot_filename=$(basename "$boot" | cut -d. -f1)
bootloader_filename=$(basename "$bootloader" | cut -d. -f1)
kernel_filename=$(basename "$kernel" | cut -d. -f1)

nasm -f bin -o "boot.flp" "$boot_filename.asm"
nasm -f bin -o "$bootloader_filename.bin" "$bootloader_filename.asm"
nasm -f bin -o "$kernel_filename.bin" "$kernel_filename.asm"

truncate -s 1474560 "boot.flp"
dd conv=notrunc if="$bootloader_filename.bin" of="boot.flp" bs=512 seek=1
echo "Writing kernel at sector 91"
dd conv=notrunc if="$kernel_filename.bin" of="boot.flp" bs=512 seek=91

rm $kernel_filename.bin

echo "File: 'boot.flp' is compiled"
