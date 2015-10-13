; print.asm
; Description: Print Functions

%ifndef  __PRINT_ASM_INCLUDED__
%define  __PRINT_ASM_INCLUDED__

[BITS 16]

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Put
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
PutWord:
          PUSH    AX
          MOV     AL, AH
          CALL    PutByte
          POP     AX
          CALL    PutByte
          RET
PutByte:
          PUSH    AX
          PUSH    CX
          MOV     AH, 0x00
          MOV     CL, 0x10
          DIV     CL
          CALL    PutHex
          MOV     AL, AH
          CALL    PutHex
          POP     CX
          POP     AX
          RET
PutHex:
          PUSH    AX
          CMP     AL, 0x0A
          JC      DoPutHex
          ADD     AL, 0x07
DoPutHex:
          ADD     AL, 0x30
          CALL    PutAscii
          POP     AX
          RET
PutAscii:
          MOV     AH, 0x0E
          MOV     BH, 0x00
          MOV     BL, 0x07
          INT     0x10
          RET

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; PrintLine
; display ASCIIZ string
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
PrintLine:
          CALL    PrintStr
PutLineFeedCode:
          MOV     SI, LineFeedCode
          CALL    PrintStr
          RET
PutSpace:
          MOV     SI, SpaceCode
          CALL    PrintStr
          RET

SpaceCode                   DB 0x20, 0x00
LineFeedCode                DB 0x0D, 0x0A, 0x00


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
          CALL    PutAscii
          JMP     StartPrintStr
PrintStrDone
          POP     BX
          POP     AX
          RET

%endif
