#!/bin/bash

bootloader="boot.asm"
kernel="kernel.asm"

filename1=$(basename "$bootloader" | cut -d. -f1)
filename2=$(basename "$kernel" | cut -d. -f1)

nasm -f bin -o "boot.flp" "$filename1.asm"
nasm -f bin -o "$filename2.bin" "$filename2.asm"

truncate -s 1474560 "boot.flp"
echo "Writing kernel at sector 91"
dd conv=notrunc if="$filename2.bin" of="boot.flp" bs=512 seek=91

rm $filename2.bin

echo "File: 'boot.flp' is compiled"
