;/*****************************
; File:boot.asm
; Description: MyOS Bootloader
;****************************/
[BITS 16]

ORG       0x7C00

;==============================
;
; Sector MAP
; (1 Sector = 512 byte)
;
; Sector 0                      : Boot Sector
; Sector 1-9 (9 sectors)        : FAT
; Sector 10-18 (9 sectors)      : FAT(Reserved)
; Sector 19-32 (14 sectors)     : Root Directory
; Sector 33-2879 (2849 sectors) : File
;
;==============================

;********************************
; Sector 0: Boot Sector BEGIN
;*******************************

;==============================
; BIOS parameter blocks(FAT12)
;==============================
JMP SHORT         BOOT                ;BS_jmpBoot
BS_jmpBoot2       DB    0x90
BS_OEMName        DB    "MyOS    "    ;OEMName(8bytes required)
BPB_BytsPerSec    DW    0x0200        ;BytesPerSector(512)
BPB_SecPerClus    DB    0x01          ;SectorPerCluster
BPB_RsvdSecCnt    DW    0x0001        ;ReservedSectors
BPB_NumFATs       DB    0x02          ;TotalFATs
BPB_RootEntCnt    DW    0x00E0        ;MaxRootEntries(1.44M=1474560/512bytes=0xE0(224))
BPB_TotSec16      DW    0x0B40        ;TotalSectors
BPB_Media         DB    0xF0          ;MediaDescriptor(0xF0=RemovableMedia)
BPB_FATSz16       DW    0x0009        ;SectorsPerFAT
BPB_SecPerTrk     DW    0x0012        ;SectorsPerTrack(0x12(18))
BPB_NumHeads      DW    0x0002        ;NumHeads
BPB_HiddSec       DD    0x00000000    ;HiddenSector
BPB_TotSec32      DD    0x00000000    ;TotalSectors

BS_DrvNum         DB    0x00          ;DriverNumber
BS_Reserved1      DB    0x00          ;Reserved
BS_BootSig        DB    0x29          ;BootSignature
BS_VolID          DD    0x20151004    ;VolumeSerialNumber
BS_VolLab         DB    "MyOS       " ;VolumeLabel(11bytes reqired)
BSFilSysType      DB    "FAT12   "    ;FileSystemType(8bytes required)


;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; BOOT
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
BOOT:
          CLI
; Initialize Data Segment
          XOR     AX, AX
          MOV     DS, AX
          MOV     ES, AX
          MOV     ES, AX
          MOV     FS, AX
          MOV     GS, AX

          XOR     BX, BX
          XOR     CX, CX
          XOR     DX, DX

; Initialize Stack Segment and Stack Pointer
          MOV     SS, AX
          MOV     SP, 0xFFFC

; Show Message
          MOV     SI, ImageName
          CALL    DisplayLine

; Reset Floppy Drive
          CALL    ResetFloppyDrive
; Load FAT
          CALL    LOAD_FAT
          HLT

ImageName                   DB "MyOS Boot Loader", 0x00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; DisplayLine
; display ASCIIZ string
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
DisplayLine:
          PUSH    AX
          PUSH    BX
          CALL    DisplayString
          MOV     SI, LineFeedCode
          CALL    DisplayString
          POP     BX
          POP     AX
          RET

LineFeedCode                DB 0x0D, 0x0A, 0x00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; DisplayString
; display ASCIIZ string
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
DisplayString:
          PUSH    AX
          PUSH    BX
StartDispStr:
          LODSB
          OR      AL, AL
          JZ      .DONE
          MOV     AH, 0x0E
          MOV     BH, 0x00
          MOV     BL, 0x07
          INT     0x10
          JMP     StartDispStr
.DONE:
          POP     BX
          POP     AX
          RET

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; ResetFloppyDrive
; Reset Floppy Drive
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
ResetFloppyDrive:
          MOV   AH, 0x00
          MOV   DL, 0x00
          INT   0x13
          JC FAILURE
; Show Success Message
          MOV     SI, ResetFloppyDriveSuccess
          CALL    DisplayLine
          RET
FAILURE:
; Show Fail Message
          MOV     SI, ResetFloppyDriveFail
          CALL    DisplayLine
          HLT

ResetFloppyDriveSuccess     DB "Reset Floppy Drive.....Success", 0x00
ResetFloppyDriveFail        DB "Reset Floppy Drive.....Fail", 0x00


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

physicalSector  DB 0x00
physicalHead    DB 0x00
physicalTrack   DB 0x00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Load FAT From Floppy
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
LOAD_FAT:
; FATをアドレス0x7E00に読み込む
          MOV     BX, WORD [BX_FAT_ADDR]        ; FATを読み込むアドレス0x7E00を引数BXに代入
          ADD     AX, WORD [BPB_RsvdSecCnt]     ; FATの開始セクタを取得
          XCHG    AX, CX                        ; FATの開始セクタを一旦CXレジスタに退避
          MOV     AX, WORD [BPB_FATSz16]        ; FATのサイズを計算(FATのセクタ数を取得)
          MUL     BYTE [BPB_NumFATs]            ; FATの予備領域も念のため読み込む
                                                ; AX x BPB_NumFATs => AX
          XCHG    AX, CX                        ; CXにFATのサイズ、AXにFATの開始セクタ
READ_FAT:
          CALL    ReadSector                    ; FATを1セクタずつ読み込む
          ADD     BX, WORD [BPB_BytsPerSec]     ; 1セクタを読み込んだので格納アドレスに512バイト足す
          INC     AX                            ; 次のセクタを読み込むのでAXに1を足す
          DEC     CX                            ; 残りのFATサイズを1セクタ減らす
          JCXZ    FAT_LOADED                    ; CX=0でZFが立ったら読み込み終了
          JMP     READ_FAT                      ; 次のセクタの読み込み
FAT_LOADED:
          MOV     SI, FatLoadedMessage
          CALL    DisplayLine
          RET

FatLoadedMessage     DB "FAT Loaded.", 0x00
BX_FAT_ADDR       DW 0x7E00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; ReadSector
; Read 1 Sector
; Input
;   BX: 読み込んだセクタを格納するアドレス
;   AX: 読み込みたい論理セクタ(LBA)
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
ReadSector:
          MOV     DI, 0x0005                ; エラー発生時5回までリトライする
SECTORLOOP:
          PUSH    AX                        ; AX, BX, CX をスタックに退避
;          PUSH    BX
          PUSH    CX
          MOV     SI, ReadSectorBeginMessage
          CALL    DisplayString
          CALL    LBA2CHS                   ; 論理セクタを物理セクタに変換
          MOV     AH, 0x02                  ; セクタ読み込みモード
          MOV     AL, 0x01                  ; 1つのセクタだけ読み込み
          MOV     CH, BYTE [physicalTrack]  ; Track
          MOV     CL, BYTE [physicalSector] ; Sector
          MOV     DH, BYTE [physicalHead]   ; Head
          MOV     DL, BYTE [BS_DrvNum]      ; Drive
          INT     0x13                      ; BIOS処理呼び出し
          JNC     ReadSectorSuccess         ; CFを見て成功失敗を判定
          ; エラー発生時の処理
          MOV     SI, ReadSectorFailMessage
          CALL    DisplayLine
          XOR     AX, AX
          INT     0x13                      ; ヘッドを初期位置に戻す
          DEC     DI                        ; エラーカウンタを減らす
          POP     CX                        ; AX, BX, CX の退避データを元に戻す
;          POP     BX
          POP     AX
          JNZ     SECTORLOOP                ; 読み取りのリトライ
          ; 読み取り失敗
          INT     0x18                      ; 謎
          MOV     SI, ReadSectorFailEndMessage
          CALL    DisplayLine
          HLT
ReadSectorSuccess:
          MOV     SI, ReadSectorSuccessMessage
          CALL    DisplayLine
          POP     CX
          POP     AX
          RET

;          MOV BX, 0x1000                  ;
;          MOV ES, BX                      ; アドレス0x10000から開始するセグメントに読み込みます
;          MOV BX, 0x0000                  ; セグメントの最初(オフセット0x0000)に読み込みます。
;          INT 0x13                        ; セクタを読み込みます
;          RET

ReadSectorBeginMessage  DB "ReadSector...", 0x00
ReadSectorSuccessMessage  DB "Success", 0x00
ReadSectorFailMessage  DB "Fail", 0x00
ReadSectorFailEndMessage  DB "ReadSectorFail", 0x00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Data Section
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/


TIMES 510 - ($ - $$) DB 0

DW 0xAA55

;********************************
; Sector 0: Boot Sector END
;*******************************


