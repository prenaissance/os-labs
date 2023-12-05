#!/bin/bash

bootloader="boot.asm"
kernel="kernel.asm"

filename1=$(basename "$bootloader" | cut -d. -f1)
filename2=$(basename "$kernel" | cut -d. -f1)

nasm -f bin -o "$filename1.bin" "$filename1.asm"
nasm -f bin -o "$filename2.bin" "$filename2.asm"

cat "$filename1.bin" "$filename2.bin" > "boot.flp"

truncate -s 1474560 "boot.flp"

rm $filename1.bin $filename2.bin

echo "File: 'boot.flp' is compiled"
