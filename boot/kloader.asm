; File:kloader.asm
; Description: MyOS Kernel Loader

[BITS 16]
ORG 0x0500

          JMP     KLoader_Main

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Preprocessor directives
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
%include "boot/print.asm"
%include "boot/fat12.asm"
%include "boot/a20line.asm"
%include "boot/dump.asm"

[BITS 16]

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Data Section
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

WelcomeMessage              DB 0x0D, 0x0A, "Welcome To MyOS Kernel Loader", 0x0D, 0x0A, 0x00
SearchingMessage            DB "Searching Kernel Image...", 0x00
LoadingMessage              DB "Loading Kernal Image...", 0x00
EnablingA20Message          DB "Enabling A20 Line...", 0x00
SwitchingMessage            DB "Switching to Protected Mode...", 0x00
SuccessMessage              DB "SUCESS", 0x00
FailMessage                 DB "FAIL", 0x00
CriticalErrorMessage        DB "CRITICAL ERROR", 0x00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Starting Kernel Procedure
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
KLoader_Main:
          XOR     AX, AX
          XOR     BX, BX
          XOR     CX, CX
          XOR     DX, DX
          MOV     DS, AX
          MOV     ES, AX


; Show Welcome Message
          MOV     SI, WelcomeMessage
          CALL    PrintStr
          CALL    PutLineFeedCode

; Search Kernel
          MOV     SI, SearchingMessage
          CALL    PrintStr

          CALL    Find_Kernel
          CMP     AX, 0
          JNE     KLoader_Fail

          MOV     SI, SuccessMessage
          CALL    PrintLine

; Load Kernel
          MOV     SI, LoadingMessage
          CALL    PrintStr

          CALL    Load_Kernel

          MOV     SI, SuccessMessage
          CALL    PrintLine

; Enable A20 Line
          MOV     SI, EnablingA20Message
          CALL    PrintStr

          CALL    EnableA20Line
          CMP     AX, 0
          JNE     KLoader_Fail

          MOV     SI, SuccessMessage
          CALL    PrintLine

; Switch to Protected Mode
          MOV     SI, SwitchingMessage
          CALL    PrintStr
          CLI
          LGDT    [gdtr]
          JMP     Enter_pmode

KLoader_Fail:
          MOV     SI, FailMessage
          CALL    PrintLine
          HLT


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Global Descriptor Table(GDT)
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
NULL_DESC:
          DW 0x0000
          DW 0x0000
          DW 0x0000
          DW 0x0000

CODE_DESC:
          DW 0xFFFF                   ; Segment Limit Low
          DW 0x0000                   ; Base Address Low
          DB 0x00                     ; Base Address Mid
          DB 10011010b                ; Flags and Limit
          DB 11001111b                ; Access Byte
          DB 0x00                     ; Base Address Hi

DATA_DESC:
          DW 0xFFFF                   ; Segment Limit Low
          DW 0x0000                   ; Base Address Low
          DB 0x00                     ; Base Address Mid
          DB 10010010b                ; Flags and Limit
          DB 11001111b                ; Acess Byte
          DB 0x00                     ; Base Address Hi

gdtr:
    Limit dw gdtr - NULL_DESC - 1 ; length of GDT
    BASE  dd NULL_DESC ; base of GDT


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Enter 32bit Protected Mode
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
Enter_pmode:
          MOV     EAX, CR0
          OR      EAX, 0x00000001   ; without paging
          MOV     CR0, EAX
          JMP     (CODE_DESC - NULL_DESC) :Pmode_start

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Starting Protected Mode
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
[BITS 32]

Checking32BitCalcMessage    DB "Checking 32-bit Calculation...", 0x00
Checking16BitMemoryMessage  DB "Checking 16-bit Memory Access...", 0x00
Checking32BitMemoryMessage  DB "Checking 32-bit Memory Access...", 0x00

Pmode_start:
          MOV     AX, DATA_DESC - NULL_DESC
          MOV     SS, AX
          MOV     ES, AX
          MOV     FS, AX
          MOV     GS, AX
          MOV     DS, AX

          MOV     ESP, 90000h    ; initialize stac pointer
          CALL    Cls32

; Check 32-bit calculation enabled
          MOV     SI, Checking32BitCalcMessage
          CALL    PrintStr32

          MOV     EAX, 0xf0000000
          MOV     EBX, 0xf0000000
          ADD     EAX, EBX
          JAE     KLoader_Fail32  ; CF == 0

          MOV     SI, SuccessMessage
          CALL    PrintLine32

; Check 16-bit  Memory Access enabled
          MOV     SI, Checking16BitMemoryMessage
          CALL    PrintStr32

          XOR     EAX, EAX
          MOV     EBX, 0x00007000
          MOV     DWORD [EBX], 0x18E9741B
          MOV     EAX, DWORD [EBX]
          CMP     EAX, 0x18E9741B
          JNE     KLoader_Fail32  ; ZF = 0 (EAX != EBX)

          MOV     SI, SuccessMessage
          CALL    PrintLine32

; Check 32-bit  Memory Access enabled
          MOV     SI, Checking32BitMemoryMessage
          CALL    PrintStr32

          XOR     EAX, EAX
          MOV     EBX, 0x00100008
          MOV     DWORD [EBX], 0x18E9741B  ; little endian
          MOV     EAX, DWORD [EBX]
          CMP     EAX, 0x18E9741B
          JNE     KLoader_Fail32  ; ZF = 0 (EAX != EBX)

          MOV     SI, SuccessMessage
          CALL    PrintLine32
          JMP     CopyKernelImage

KLoader_Fail32:
          MOV     SI, FailMessage
          CALL    PrintLine32
          HLT

CopyKernelImage:
; get kernel image size
          XOR     EAX, EAX
          MOVZX   EAX, WORD [ImageSizeES]
          SHL     EAX, 0x4
          MOV     DWORD [KernelImageSize], EAX
; calc real mode kernel address => EBX
          XOR     EBX, EBX
          MOVZX   EBX, WORD [KERNEL_RMODE_BASE_SEG]
          SHL     EBX, 0x4
          MOVZX   EAX, WORD [KERNEL_RMODE_BASE_ADDR]
          ADD     EBX, EAX                ; EBX: from address

; copy parameters
          MOV     ECX, 0  ; ECX: copied bytes count

DoCopyKernelImage:

          MOV     EBX, KERNEL_RMODE_BASE
          ADD     EBX, ECX
          MOV     AL, BYTE [EBX]        ; EAX: temoporary byte

          MOV     EDX, KERNEL_PMODE_BASE
          ADD     EDX, ECX
          MOV     BYTE [EDX], AL        ; do copy

          INC     ECX
          CMP     ECX, DWORD [KernelImageSize]
          JNE     DoCopyKernelImage

          JMP     EXECUTE

Failure2:
          HLT
          JMP     Failure2

EXECUTE:

          ;---------------------------
          ;  Execute Kernel
          ;---------------------------
          MOV     EBX, KERNEL_PMODE_BASE
          MOV     EBP, EBX

          XOR     EBX, EBX
          CLI
          CALL    EBP
          ADD     ESP, 4
          JMP     Failure2


