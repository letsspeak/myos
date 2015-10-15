; fat12.asm
; FAT12 filesystem read only function

%ifndef __FAT12_ASM_INCLUDED__
%define __FAT12_ASM_INCLUDED__

[BITS 16]
%include "boot/bpb.asm"
%include "boot/common.asm"

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Variables
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
KernelImageCluster          DW 0x0000
datasector                  DW 0x0000
cluster                     DW 0x0000
filesize_h                  DW 0x0000
filesize_l                  DW 0x0000
physicalSector              DB 0x00
physicalHead                DB 0x00
physicalTrack               DB 0x00


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Define
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
BX_FAT_ADDR                 DW 0x0200
BX_RTDIR_ADDR               DW 0x2600
ReadSectorFailMessage       DB "FAIL to Read Sector", 0x00


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Find Kernel File
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
Find_Kernel:
        PUSHA
        MOV     BX, WORD [ES_BASE_SEG]
        MOV     ES, BX
        MOV     BX, WORD [BX_RTDIR_ADDR]
        MOV     CX, WORD [BPB_RootEntCnt]
        MOV     SI, KernelImageName

Finding_File:
        MOV     DI, BX
        PUSH    CX
        MOV     CX, 0x000B
        PUSH    DI
        PUSH    SI
REPE    CMPSB
        POP     SI
        POP     DI
        JCXZ    Found_File
        ADD     BX, 0x0020
        POP     CX
; 次のエントリへ
        LOOP    Finding_File
        JMP     FAILURE

FAILURE:
        POPA
        MOV     AX, -1
        RET

Found_File:
        POP     CX
        MOV     AX, WORD [ES:BX+0x001A]
        MOV     WORD [KernelImageCluster], AX
        POPA
        MOV     AX, 0
        RET


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Load Kernel File
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
Load_Kernel:
        PUSHA
        MOV     WORD [datasector], 0x0021
        MOV     BX, [KERNEL_RMODE_BASE_SEG]
        MOV     ES, BX
        MOV     BX, [KERNEL_RMODE_BASE_ADDR]
        PUSH    BX
        MOV     AX, WORD [KernelImageCluster]
        MOV     WORD [cluster], AX

Load_Image:
        MOV     AX, WORD [cluster]
        POP     BX
        CALL    ClusterLBA
        CALL    ReadSector
        PUSH    BX
        MOV     BX, ES
        ADD     BX, 0x0020
        MOV     ES, BX

ES_ADDED:
; 次のクラスタ番号取得
        MOV     AX, WORD [cluster]
        MOV     CX, AX
        MOV     DX, AX
        SHR     DX, 0x0001
        ADD     CX, DX
        PUSH    ES
        MOV     BX, [ES_BASE_SEG]
        MOV     ES, BX
        MOV     BX, [BX_FAT_ADDR]
        ADD     BX, CX
        MOV     DX, WORD [ES:BX]
        POP     ES
        TEST    AX, 0x0001
        JNZ     ODD_CLUSTER

EVEN_CLUSTER:
        AND     DX, 0x0FFF
        JMP     LOCAL_DONE
ODD_CLUSTER:
        SHR     DX, 0x0004
LOCAL_DONE:
        MOV     WORD [cluster], DX
        CMP     DX, 0x0FF0
        JB      Load_Image
        POP     BX

ALL_DONE:
        XOR     BX, BX
        MOV     WORD [ImageSizeBX], BX
        MOV     BX, ES
        SUB     BX, [KERNEL_RMODE_BASE_SEG]
        MOV     WORD [ImageSizeES], BX
        POPA
        RET


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; ReadSector
; Input
;   ES:BX: 読み込んだセクタを格納するアドレス
;   AX: 読み込みたい論理セクタ(LBA)

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
ReadSector:
        MOV     DI, 0x0005                ; エラーカウンタ5回まで再試行
SECTORLOOP:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        CALL    LBA2CHS                   ; 論理セクタを物理セクタに変換
        MOV     AH, 0x02                  ; セクタ読み込みモード
        MOV     AL, 0x01                  ; 1つのセクタだけ読み込み
        MOV     CH, BYTE [physicalTrack]  ; Track
        MOV     CL, BYTE [physicalSector] ; Sector
        MOV     DH, BYTE [physicalHead]   ; Head
        MOV     DL, BYTE [BS_DrvNum]      ; Drive
        INT     0x13                      ; BIOS処理呼び出し
        JNC     ReadSectorSuccess

;        MOV     AH, 0x01
;        INT     0x13

        XOR     AX, AX
        INT     0x13                      ; ヘッドを初期位置に戻す
        DEC     DI
        POP     CX
        POP     BX
        POP     AX
        JNZ     SECTORLOOP                ; Retry

        MOV     SI, ReadSectorFailMessage
        CALL    PrintLine
        INT     0x18
        HLT

ReadSectorSuccess:
        POP     CX
        POP     BX
        POP     AX
        RET


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; PROCEDURE Cluster LBA
; convert FAT cluster into LBA adressing scheme
; LBA = (cluster - 2) * sectors per cluster
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
ClusterLBA:
        SUB     AX, 0x0002
        XOR     CX, CX
        MOV     CL, BYTE [BPB_SecPerClus]
        MUL     CX
        ADD     AX, WORD [datasector]
        RET

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
; LBA2CHS
; input AX: sector number (LBA)
; output AX: quotient DX:Remainder
; convert logical address to physical address
; physical sector = (LBA MOD sectors per track) + 1
; physical head   = (LBA / sectors per track) MOD number of headds
; physical track  = LBA / (sectors per track * number of heads)
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
LBA2CHS:
        XOR     DX, DX                        ; initialize DX
        DIV     WORD [BPB_SecPerTrk]          ; calculate
        INC     DL                            ; +1
        MOV     BYTE [physicalSector], DL
        XOR     DX, DX                        ; initialize DX
        DIV     WORD [BPB_NumHeads]           ; calculate
        MOV     BYTE [physicalHead], DL
        MOV     BYTE [physicalTrack], AL
        RET

%endif
