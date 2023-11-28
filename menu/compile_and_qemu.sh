#!/bin/bash

sh ./compile.sh
qemu-system-x86_64 -drive file=boot.flp,format=raw,index=0,if=floppy