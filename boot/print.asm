; print.asm
; Description: Print Functions

%ifndef  __PRINT_ASM_INCLUDED__
%define  __PRINT_ASM_INCLUDED__

[BITS 16]

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; PrintStr
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
PrintStr:
          PUSH    AX
          PUSH    BX
StartPrintStr:
          LODSB
          OR      AL, AL
          JZ      PrintStrDone
          MOV     AH, 0x0E
          MOV     BH, 0x00
          MOV     BL, 0x07
          INT     0x10
          JMP     StartPrintStr
PrintStrDone
          POP     BX
          POP     AX
          RET

%endif
