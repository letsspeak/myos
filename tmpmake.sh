#!/bin/sh

gcc -fomit-frame-pointer -O2 -masm=intel -Wall kernel/kernel.c -o temp/kernel.o -c
ld -T kernel/ld.script -Map temp/kernel.map -nostdlib -e _kernel_entry --oformat binary temp/kernel.o -o temp/KImage
