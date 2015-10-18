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

; Switch to Protected Mode
          MOV     SI, SwitchingMessage
          CALL    PrintStr

          CLI
          LGDT    [gdtr]
          CALL    Enable_A20
          JMP     Enter_pmode

KLoader_Fail:
          MOV     SI, FailMessage
          CALL    PrintLine
          HLT

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
          DB 10011010b                ; Type(4), S(1), DPL(2), P(1)
          DB 11001111b                ; Segment Limit Hi(4), AVL(1), 0, D/B(1), G(1)
          DB 0x00                     ; Base Address Hi

DATA_DESC:
          DW 0xFFFF                   ; Segment Limit Low
          DW 0x0000                   ; Base Address Low
          DB 0x00                     ; Base Address Mid
          DB 10010010b                ; Type(4), S(1), DPL(2), P(1)
          DB 11001111b                ; Segment Limit Hi(4), AVL(1), 0, D/B(1), G(1)
          DB 0x00                     ; Base Address Hi

gdtr:
    Limit dw gdtr - NULL_DESC - 1 ; length of GDT
    BASE  dd NULL_DESC ; base of GDT


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Enable A20
;
; Enable A20 via Keybord Controller
;
; == Port Addresses of Keyboard Controller
;   0x060 Read  Read Buffer
;   0x060 Write Write Buffer
;   0x064 Read  Status Register
;   0x064 Write Controller Command Byte
;
; == Status Register Bits
;   See "11.1 The keyboard controller status register"
;   https://www.win.tue.nl/~aeb/linux/kbd/scancodes-11.html
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
Enable_A20:
          CALL    A20_Flag_Wait
          MOV     AL, 0xAD        ; 0xAD Disable Keyboard
          OUT     0x64, AL        ; Controller Command

          CALL    A20_Flag_Wait
          MOV     AL, 0xD0        ; Read Output Port
          OUT     0x64, AL        ; Controller Command

          CALL    A20_Output_Wait
          IN      AL, 0x60        ; Read Buffer
          PUSH    EAX

          CALL    A20_Flag_Wait
          MOV     AL, 0xD1        ; Write Output Port
          OUT     0x64, AL        ; Controller Command

          CALL    A20_Flag_Wait
          POP     EAX
          OR      AL, 0x2         ; (0010b) A20 Enable Bit
          OUT     0x60, AL        ; Write Buffer

          CALL    A20_Flag_Wait
          MOV     AL, 0xAE        ; 0xAE Enable Keyboard
          OUT     0x64, AL        ; Controller Command

          CALL    A20_Flag_Wait
          RET

A20_Flag_Wait:
          IN      AL, 0x64        ; Read Status Register
          TEST    AL, 0x2         ; Check System Flag
          JNZ     A20_Flag_Wait
          RET

A20_Output_Wait
          IN      AL, 0x64        ; Read Status Register
          TEST    AL, 0x1         ; Check Input Buffer Full
          JZ      A20_Output_Wait
          RET



;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Starting Protected Mode
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
[BITS 32]
Pmode_start:
          MOV     AX, DATA_DESC - NULL_DESC
          MOV     SS, AX
          MOV     ES, AX
          MOV     FS, AX
          MOV     GS, AX
          MOV     DS, AX

          MOV     ESP, 90000h    ; initialize stac pointer

CopyKernelImage:
; get kernel image size
          XOR     EAX, EAX
          MOVZX   EAX, WORD [ImageSizeES]
          SHL     EAX, 0x4
          MOV     DWORD [KernelImageSize], EAX
; copy
          CLD
          MOV     ESI, [KERNEL_RMODE_BASE_SEG]
          MOV     EDI, [KERNEL_PMODE_BASE]
          MOV     ECX, EAX
REP       MOVSD
          JMP     EXECUTE


Failure2:
          HLT
          JMP     Failure2

EXECUTE:

; dump memory test
;          MOV     EBX, [KERNEL_RMODE_BASE_SEG]
;          MOV     ECX, 0x0D
;          CALL    DumpMemory32
;          HLT

          ;---------------------------
          ;  Execute Kernel
          ;---------------------------
          MOV     EBX, [KERNEL_PMODE_BASE]
          MOV     EBP, EBX

          XOR     EBX, EBX
          CLI
          CALL    EBP
          ADD     ESP, 4
          JMP     Failure2

