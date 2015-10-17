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

[BITS 32]

DISPLAY_MEMSIZE DD 0x02
DISPLAY_WIDTH DD 0x50
DISPLAY_HEIGHT DD 0x19

CURSOR_X DD 0x4F
CURSOR_Y DD 0x0

PutAscii32:
          PUSH    EAX
          PUSH    EBX

          OR      EAX, 0x00000700
          PUSH    EAX

          MOV     EAX, DWORD [DISPLAY_MEMSIZE]
          MUL     DWORD [CURSOR_X]
          MOV     EBX, EAX

          MOV     EAX, DWORD [DISPLAY_WIDTH]
          MUL     DWORD [CURSOR_Y]
          ADD     EBX, EAX
          OR      EBX, 0x000B8000

          POP     EAX
          MOV     [EBX], EAX

          MOV     EAX, DWORD [CURSOR_X]
          MOV     EBX, DWORD [CURSOR_Y]
          INC     EAX
          CMP     EAX, DWORD [DISPLAY_WIDTH]
          JNE     PutAsciiIncCursorCompleted

          MOV     EAX, 0
          MOV     EBX, DWORD [CURSOR_Y]
          INC     EBX
          CMP     EBX, DWORD [DISPLAY_HEIGHT]
          JNE     PutAsciiIncCursorCompleted
          MOV     EBX, 0

PutAsciiIncCursorCompleted:
          MOV     DWORD [CURSOR_X], EAX
          MOV     DWORD [CURSOR_Y], EBX
          POP     EBX
          POP     EAX
          RET

Cls32:
          MOV     EAX, DWORD [DISPLAY_WIDTH]
          MUL     DWORD [DISPLAY_HEIGHT]
          MOV     ECX, EAX
          MOV     EBX, 0x000B8000
Cls32PutSpace:
          MOV     EAX, 0x07200720
          MOV     [EBX], EAX
          ADD     EBX, 4
          SUB     ECX, 2
          JNZ    Cls32PutSpace
          RET

%endif
