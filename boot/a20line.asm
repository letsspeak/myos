; a20line.asm
; enable A20 Line
; http://wiki.osdev.org/A20_Line

%ifndef __A20LINE_ASM_INCLUDED__
%define __A20LINE_ASM_INCLUDED__

[BITS 16]

EnableA20Line:

; PICが一切の割り込みを受け付けないようにする
;	AT互換機の仕様では、PICの初期化をするなら、
;	こいつをCLI前にやっておかないと、たまにハングアップする
;	PICの初期化はあとでやる

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; OUT命令を連続させるとうまくいかない機種があるらしいので
		OUT		0xa1,AL

		CLI						; さらにCPUレベルでも割り込み禁止


    CALL  waitkbdout
    MOV   AL,0xd1
    OUT   0x64,AL
    CALL  waitkbdout
    MOV   AL,0xdf     ; enable A20
    OUT   0x60,AL
    CALL  waitkbdout
    MOV   AX, 0
    RET

; Test if A20 is alread enabled
        CALL    check_a20
        CMP     AX, 0
        JNE     EnableA20LineSuccess

; Try the BIOS funcion
        MOV     AX, 0x2401
        INT     0x15
; Test if A20 is enabled
        JB      EnableA20BIOSFunctionFail ; CF == 1 ==> Fail
        CMP     AH, 0x00
        JNE     EnableA20BIOSFunctionFail ; CF == 0 && AH != 0x00 => Fail
        CMP     AH, 0x86
        JE      EnableA20BIOSFunctionFail ; AH == 0x86 => Fail
        ; Success
        JMP     EnableA20LineSuccess

EnableA20BIOSFunctionFail:

;TODOs
;Try the keyboard controller method.
;Test if A20 is enabled in a loop with a time-out (as the keyboard controller method may work slowly)
;Try the Fast A20 method last

        IN      AL, 0x92
        OR      AL, 2
        OUT     0x92, AL;
;        JMP     EnableA20LineSuccess


;Test if A20 is enabled in a loop with a time-out (as the fast A20 method may work slowly)

EnableA20LineFail
        MOV     AX, -1
        RET

EnableA20LineSuccess:
        MOV     AX, 0
        RET

waitkbdout:
    IN     AL,0x64
    AND    AL,0x02
    JNZ   waitkbdout    ; ANDの結果が0でなければwaitkbdoutへ
    RET

; Function: check_a20
;
; Purpose: to check the status of the a20 line in a completely self-contained state-preserving way.
;          The function can be modified as necessary by removing push's at the beginning and their
;          respective pop's at the end if complete self-containment is not required.
;
; Returns: 0 in ax if the a20 line is disabled (memory wraps around)
;          1 in ax if the a20 line is enabled (memory does not wrap around)
 
check_a20:
    pushf
    push ds
    push es
    push di
    push si

    cli

    xor ax, ax ; ax = 0
    mov es, ax

    not ax ; ax = 0xFFFF
    mov ds, ax

    mov di, 0x0500
    mov si, 0x0510

    mov al, byte [es:di]
    push ax

    mov al, byte [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF

    pop ax
    mov byte [ds:si], al

    pop ax
    mov byte [es:di], al

    mov ax, 0
    je check_a20__exit

    mov ax, 1

check_a20__exit:
    pop si
    pop di
    pop es
    pop ds
    popf

    ret

;;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;;
;; Enable A20
;;
;; Enable A20 via Keybord Controller
;;
;; == Port Addresses of Keyboard Controller
;;   0x060 Read  Read Buffer
;;   0x060 Write Write Buffer
;;   0x064 Read  Status Register
;;   0x064 Write Controller Command Byte
;;
;; == Status Register Bits
;;   See "11.1 The keyboard controller status register"
;;   https://www.win.tue.nl/~aeb/linux/kbd/scancodes-11.html
;;
;;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;Enable_A20:
;          CALL    A20_Flag_Wait
;          MOV     AL, 0xAD        ; 0xAD Disable Keyboard
;          OUT     0x64, AL        ; Controller Command
;
;          CALL    A20_Flag_Wait
;          MOV     AL, 0xD0        ; Read Output Port
;          OUT     0x64, AL        ; Controller Command
;
;          CALL    A20_Output_Wait
;          IN      AL, 0x60        ; Read Buffer
;          PUSH    EAX
;
;          CALL    A20_Flag_Wait
;          MOV     AL, 0xD1        ; Write Output Port
;          OUT     0x64, AL        ; Controller Command
;
;          CALL    A20_Flag_Wait
;          POP     EAX
;          OR      AL, 0x2         ; (0010b) A20 Enable Bit
;          OUT     0x60, AL        ; Write Buffer
;
;          CALL    A20_Flag_Wait
;          MOV     AL, 0xAE        ; 0xAE Enable Keyboard
;          OUT     0x64, AL        ; Controller Command
;
;          CALL    A20_Flag_Wait
;          RET
;
;A20_Flag_Wait:
;          IN      AL, 0x64        ; Read Status Register
;          TEST    AL, 0x2         ; Check System Flag
;          JNZ     A20_Flag_Wait
;          RET
;
;A20_Output_Wait
;          IN      AL, 0x64        ; Read Status Register
;          TEST    AL, 0x1         ; Check Input Buffer Full
;          JZ      A20_Output_Wait
;          RET

%endif
