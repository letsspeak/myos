; common.asm
; BIOS parameter block

%ifndef __COMMON_ASM_INCLUDED__
%define __COMMON_ASM_INCLUDED__

ES_BASE_SEG               DW 0x07C0
KERNEL_PMODE_BASE         EQU 0x00100000
;KERNEL_PMODE_BASE         DD 0x0008F000
KERNEL_RMODE_BASE_SEG     DW 0x0BE0
KERNEL_RMODE_BASE_ADDR    DW 0x0000

KernelImageName DB "KERNEL  IMG ", 0x00 ; length = 11

KernelImageSize     DD 0x00000000
ImageSizeBX         DW 0x0000
ImageSizeES         DW 0x0000

%endif
