; fat12.asm
; FAT12 filesystem read only function

%ifndef __FAT12_ASM_INCLUDED__
%define __FAT12_ASM_INCLUDED__

[BITS 16]
%include "boot/bpb.asm"

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Variables
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
KernelImageCluster  DW 0x0000


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Define
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
%define ES_BASE_SEG         0x07C0
%define KERNEL_BASE_SEG     0x1000
%define KERNEL_BASE_ADDR    0x0000
%define BX_FAT_ADDR         0x0200
%define BX_RTDIR_ADDR       0x2600


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Find Kernel File
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
Find_Kernel:
        PUSHA
        MOV     BX, ES_BASE_SEG
        MOV     ES, BX





%endif
