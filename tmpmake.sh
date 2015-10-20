#!/bin/sh

gcc -c -o temp/kerenel.o kernel/kernel.c -O2 -Wall
ld -T kernel/kernel.lds -Map kernel.map -nostdlib -e _kernel_entry --oformat binary -o temp/KImage temp/kernel.o
