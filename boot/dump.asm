; dump.asm
; Dump Functions

%ifndef  __DUMP_ASM_INCLUDED__
%define  __DUMP_ASM_INCLUDED__

[BITS 16]

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; DumpMemory
; ES:BX: Memory Address
; CX: Size
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
DumpMemory:
DUMP_LOOP:
          MOV     AL, BYTE [ES:BX]
          PUSH    BX
          CALL    PutByte
          CALL    PutSpace
          POP     BX
          INC     BX
          DEC     CX
          JCXZ    DUMP_LOOP_DONE
          JMP     DUMP_LOOP
DUMP_LOOP_DONE:
          CALL    PutLineFeedCode
          RET

%endif
