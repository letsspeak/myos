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
PrintStrDone:
          POP     BX
          POP     AX
          RET

[BITS 32]

DISPLAY_MEMSIZE DD 0x02
DISPLAY_WIDTH DD 0x50
DISPLAY_HEIGHT DD 0x19

CURSOR_X DD 0x0
CURSOR_Y DD 0x0

ASCII_CR_CODE DB 0x0D
ASCII_LF_CODE DB 0x0A
ASCII_SP_CODE DB 0x20

SetCursor32:
          PUSH    EAX
          AND     EAX, 0x000000FF
          MOV     DWORD [CURSOR_X], EAX
          POP     EAX
          PUSH    EAX
          MOV     AL, AH
          AND     EAX, 0x000000FF
          MOV     DWORD [CURSOR_Y], EAX
          POP     EAX
          RET

Cls32:
          PUSHA
          MOV     EAX, DWORD [DISPLAY_WIDTH]
          MUL     DWORD [DISPLAY_HEIGHT]
          MOV     ECX, EAX
          MOV     EBX, 0x000B8000
Cls32PutSpace:
          MOV     EAX, 0x07200720
          MOV     [EBX], EAX
          ADD     EBX, 4
          SUB     ECX, 2
          JNZ     Cls32PutSpace
          XOR     EAX, EAX
          CALL    SetCursor32
          POPA
          RET

PutAscii32:
          PUSH    EAX
          CALL    CheckControlCode32
          CMP     AX, 0
          JNE     PutAscii32Return
          POP     EAX

          PUSH    EAX
          PUSH    EBX

          AND     EAX, 0x000000FF
          OR      EAX, 0x00000700
          PUSH    EAX

          MOV     EAX, DWORD [DISPLAY_MEMSIZE]
          MUL     DWORD [CURSOR_X]
          MOV     EBX, EAX

          MOV     EAX, DWORD [DISPLAY_MEMSIZE]
          MUL     DWORD [DISPLAY_WIDTH]
          MUL     DWORD [CURSOR_Y]
          ADD     EBX, EAX
          OR      EBX, 0x000B8000

          POP     EAX
          MOV     [EBX], EAX

          MOV     EAX, DWORD [CURSOR_X]
          MOV     EBX, DWORD [CURSOR_Y]
          INC     EAX
          CMP     EAX, DWORD [DISPLAY_WIDTH]
          JNE     PutAscii32IncCursorCompleted

          MOV     EAX, 0
          MOV     EBX, DWORD [CURSOR_Y]
          INC     EBX
          CMP     EBX, DWORD [DISPLAY_HEIGHT]
          JNE     PutAscii32IncCursorCompleted
          MOV     EBX, 0

PutAscii32IncCursorCompleted:
          MOV     DWORD [CURSOR_X], EAX
          MOV     DWORD [CURSOR_Y], EBX
          POP     EBX
PutAscii32Return:
          POP     EAX
          RET


CheckControlCode32:
          ; switch (AL)
          CMP     AL, BYTE [ASCII_CR_CODE]
          JE      CheckControlCode32CRCode
          CMP     AL, BYTE [ASCII_LF_CODE]
          JE      CheckControlCode32LFCode
          CMP     AL, BYTE [ASCII_SP_CODE]
          JE      CheckControlCode32SPCode
          JMP     CheckControlCode32ReturnFalse

CheckControlCode32CRCode:
          ;ASCII_CR_CODE
          MOV     EAX, 0
          MOV     DWORD [CURSOR_X], EAX
          JMP     CheckControlCode32ReturnTrue
CheckControlCode32LFCode:
          ;ASCII_LF_CODE
          MOV     EAX, DWORD [CURSOR_Y]
          INC     EAX
          MOV     DWORD [CURSOR_Y], EAX
          JMP     CheckControlCode32ReturnTrue
CheckControlCode32SPCode:
          ;ASCII_SP_CODE
          MOV     EAX, DWORD [CURSOR_X]
          INC     EAX
          MOV     DWORD [CURSOR_X], EAX
          JMP     CheckControlCode32FixCursor
CheckControlCode32FixCursor:
          MOV     EBX, DWORD [CURSOR_Y]
          MOV     EAX, DWORD [CURSOR_X]
          CMP     EAX, DWORD [DISPLAY_WIDTH]
          JNE     CheckControlCode32FixCursorCompleted

          MOV     EAX, 0
          CMP     EBX, DWORD [DISPLAY_HEIGHT]
          JNE     CheckControlCode32FixCursorCompleted
          MOV     EBX, 0
CheckControlCode32FixCursorCompleted:
          MOV     DWORD [CURSOR_X], EAX
          MOV     DWORD [CURSOR_Y], EBX
          JMP     CheckControlCode32ReturnTrue
CheckControlCode32ReturnFalse:
          MOV     EAX, 0
          RET
CheckControlCode32ReturnTrue:
          MOV     EAX, 1
          RET

PutWord32:
          PUSH    EAX
          MOV     AL, AH
          CALL    PutByte32
          POP     EAX
          CALL    PutByte32
          RET
PutByte32:
          PUSH    EAX
          PUSH    ECX
          AND     EAX, 0x000000FF
          MOV     CL, 0x10
          DIV     CL
          CALL    PutHex32
          MOV     AL, AH
          CALL    PutHex32
          POP     ECX
          POP     EAX
          RET
PutHex32:
          PUSH    EAX
          CMP     AL, 0x0A
          JC      DoPutHex32
          ADD     AL, 0x07
DoPutHex32:
          ADD     AL, 0x30
          CALL    PutAscii32
          POP     EAX
          RET

PutDoubleWord32:
          PUSHA
          XOR     ECX, ECX
          MOV     CL, 0x20
          PUSH    EAX
PutDoubleWord32Loop:
          SUB     CL, 0x08
          POP     EAX
          PUSH    EAX
          SHR     EAX, CL
          AND     EAX, 0x000000FF
          CALL    PutByte32
          CALL    PutSpace32
          CMP     CL, 0
          JNE     PutDoubleWord32Loop
          POP     EAX
          POPA
          RET


PrintStr32:
          PUSH    AX
          PUSH    BX
StartPrintStr32:
          LODSB
          OR      AL, AL
          JZ      PrintStrDone32
          CALL    PutAscii32
          JMP     StartPrintStr32
PrintStrDone32:
          POP     BX
          POP     AX
          RET

PrintLine32:
          CALL    PrintStr32
PutLineFeedCode32:
          MOV     SI, LineFeedCode
          CALL    PrintStr32
          RET

PutSpace32:
          PUSH    EAX
          MOV     EAX, 0x00000020
          CALL    PutAscii32
          POP     EAX
          RET


%endif
