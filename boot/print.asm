; print.asm
; Description: Print Functions

%ifndef  __PRINT_ASM_INCLUDED__
%define  __PRINT_ASM_INCLUDED__

[BITS 16]

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; DisplayMessage
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
DisplayMessage:
          PUSH    AX
          PUSH    BX
StartDispMsg:
          LODSB
          OR      AL, AL
          JZ      .DONE
          MOV     AH, 0x0E
          MOV     BH, 0x00
          MOV     BL, 0x07
          INT     0x10
          JMP     StartDispMsg
.DONE
          POP     BX
          POP     AX
          RET

%endif
