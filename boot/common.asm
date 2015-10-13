; common.asm
; BIOS parameter block

%ifndef __COMMON_ASM_INCLUDED__
%define __COMMON_ASM_INCLUDED__

%define KERNEL_PMODE_BASE 0x100000
%define KERNEL_RMODE_BASE 0x8000
%define KernelImageName DB "KERNEL IMG ", 0x00 ; length = 11

KernelImageSize     DD 0x00000000
ImageSizeBX         DW 0x0000
ImageSizeES         DW 0x0000

%endif
