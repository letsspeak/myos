; File:loader.asm
; Description: MyOS Kernel Loader

[BITS 16]
ORG 0x500

          JMP     MAIN2

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Preprocessor directives
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
%include "boot/print.asm"


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Data Section
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
msgphello                   DB 0x0D, 0x0A, "Hello", 0x0D, 0x0A, 0x00


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Starting Kernel Procedure
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
MAIN2:
          XOR     AX, AX
          XOR     BX, BX
          XOR     CX, CX
          XOR     DX, DX
          MOV     DS, AX
          MOV     ES, AX
          MOV     SI, msgphello
          CALL    DisplayMessage
          HLT

