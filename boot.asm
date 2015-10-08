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

; Debug Print Word Values
;          PUSH    AX
;          MOV     AX, 0xFFFF
;PUT_LOOP:
;          INC     AX
;          CALL    PutWord
;          PUSH    AX
;          MOV     AL, 0x20
;          CALL    PutAscii
;          POP     AX
;          CMP     AX, 0xFFFF
;          JNZ     PUT_LOOP
;          POP     AX
;          HLT

; Reset Floppy Drive
          CALL    ResetFloppyDrive
; Load FAT
          CALL    LOAD_FAT
          ; RESULT :
          ;   AX => Root Directory Start Sector Number
          CALL    LOAD_ROOT
          ; RESULT :
          ;   AX => Root Directory Start Sector Number
          ;   CX => Root Directory Sector Count
          CALL    BROWSE_ROOT_DIRECTORY

          HLT

datasector                  DW 0x0000
ImageName                   DB "MyOS Boot Loader", 0x00
BrowseFileName              DB "TEST", 0x00

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
;          MOV     SI, ResetFloppyDriveBeginMessage
;          CALL    DisplayString
          MOV   AH, 0x00
          MOV   DL, 0x00
          INT   0x13
          JC FAILURE
; Show Success Message
;          MOV     SI, SuccessMessage
;          CALL    DisplayLine
          RET
FAILURE:
; Show Fail Message
;          MOV     SI, FailMessage
;          CALL    DisplayLine
          HLT

;ResetFloppyDriveBeginMessage     DB "Reset Floppy Drive.....", 0x00

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
; FATをBX_FAT_ADDRに読み込む
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
LOAD_FAT:
          MOV     SI, LoadFatBeginMessage
          CALL    DisplayString
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
          MOV     SI, SuccessMessage
          CALL    DisplayLine
          RET

LoadFatBeginMessage     DB "FAT...", 0x00
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
;          MOV     SI, ReadSectorBeginMessage
;          CALL    DisplayString
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
;          MOV     SI, FailMessage
;          CALL    DisplayLine
          XOR     AX, AX
          INT     0x13                      ; ヘッドを初期位置に戻す
          DEC     DI                        ; エラーカウンタを減らす
          POP     CX                        ; AX, BX, CX の退避データを元に戻す
;          POP     BX
          POP     AX
          JNZ     SECTORLOOP                ; 読み取りのリトライ
          ; 読み取り失敗
          INT     0x18                      ; 謎
;          MOV     SI, ReadSectorFailEndMessage
;          CALL    DisplayLine
          HLT
ReadSectorSuccess:
;          MOV     SI, SuccessMessage
;          CALL    DisplayLine
          POP     CX
          POP     AX
          RET

;          MOV BX, 0x1000                  ;
;          MOV ES, BX                      ; アドレス0x10000から開始するセグメントに読み込みます
;          MOV BX, 0x0000                  ; セグメントの最初(オフセット0x0000)に読み込みます。
;          INT 0x13                        ; セクタを読み込みます
;          RET

;ReadSectorBeginMessage  DB "ReadSector...", 0x00
;ReadSectorFailEndMessage  DB "ReadSectorFail", 0x00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; LOAD_ROOT
; Load Root Directory
; input
;   AX: Root Directory Sector Number
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
LOAD_ROOT:
          MOV     BX, WORD [BX_RTDIR_ADDR]  ; BX_RTDIR_ADDRのアドレスに格納します
          XOR     CX, CX                    ; CXレジスタを初期化
          MOV     WORD [datasector], AX
          XCHG    AX, CX                    ; ルートディレクトリ開始セクタ番号をCXに退避
          MOV     AX, 0x0020                ; エントリのサイズは32バイト(0x0020)
          MUL     WORD [BPB_RootEntCnt]     ; エントリ数×エントリサイズをAXに格納
          ADD     AX, WORD [BPB_BytsPerSec] ; AXに1セクタのバイト数を足す
          DEC     AX                        ; AXから1を引く
          DIV     WORD [BPB_BytsPerSec]     ; AX÷1セクタのバイト数
          XCHG    AX, CX                    ; AX = ルートディレクトリ開始セクタ番号、CX= ルートディレクトリセクタ数
          ADD     WORD [datasector], CX     ; datasector => ファイル領域の開始セクタ番号
          RET

BX_RTDIR_ADDR       DW 0x8E00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; BROWSE_ROOT_DIRECTORY
; Browse Root Directory
; Requre:
;   BX_RTDIR_ADDR
;   BPB_RootEntCnt
; Input
;   BrowseFileName
; Output
;   AX : 開始クラスタ番号
;   BX : File Address on Memory
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
BROWSE_ROOT_DIRECTORY:
          MOV     SI, BrowseRootDirBeginMessage
          CALL    DisplayString
          MOV     BX, WORD[BX_RTDIR_ADDR]   ; 読み込んだルートディレクトリのアドレスを取得します
          MOV     CX, WORD[BPB_RootEntCnt]  ; エントリの数を取得します
          MOV     SI, BrowseFileName        ; 読み込みたいファイル名を取得します
;          CALL    DisplayString
;          PUSH    SI
;          MOV     SI, BrowseRootDirBeginMessage2
;          CALL    DisplayString
;          POP     SI
BROWSE_ROOT:
          MOV     DI, BX                    ; ルートディレクトリのエントリのアドレスをDIに格納
          PUSH    CX                        ; CX(エントリ数)を退避
          MOV     CX, 0x000B                ; CXに0x000B(11)を格納
          PUSH    DI                        ; DIを退避

; Show Message
          PUSH    SI
          MOV     SI, DI
          CALL    DisplayLine
          POP     SI

          PUSH    SI                        ; SIを退避
REPE      CMPSB                             ; CX(=11)文字分CMPSBを繰り返す
          POP     SI
          POP     DI
          JCXZ    BROWSE_ROOTDIR_FINISHED   ; CX=0 DIとSIの文字比較(CMPSB)結果で非一致カウントが0なら終了
          ; ファイル名不一致
          ADD     BX, 0x0020                ; 32バイト足して次のエントリへ
          POP     CX
          LOOP    BROWSE_ROOT               ; CX(エントリ数)回ループ
          ; 全てのエントリのファイル名と不一致
          JMP     BROWSE_ROOTDIR_FAILURE
BROWSE_ROOTDIR_FINISHED:
          ; ファイルを発見
          POP     CX                        ; CXの値を元に戻す
          MOV     AX, WORD [BX+0x001A]      ; 0x001A(26)バイト目の開始クラスタ番号をAXに代入
          MOV     SI, SuccessMessage
          CALL    DisplayLine
          RET
BROWSE_ROOTDIR_FAILURE:
          ; ファイルが見つからなかった
          MOV     SI, FailMessage
          CALL    DisplayLine
          HLT

BrowseRootDirBeginMessage DB "RootDir...", 0x00
;BrowseRootDirBeginMessage2 DB " ...", 0x00

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
          PUSH    AX
          PUSH    BX
          MOV     AH, 0x0E
          MOV     BH, 0x00
          MOV     BL, 0x07
          INT     0x10
          POP     BX
          POP     AX
          RET

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Data Section
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

SuccessMessage  DB "Success", 0x00
FailMessage  DB "Fail", 0x00

TIMES 510 - ($ - $$) DB 0

DW 0xAA55

;********************************
; Sector 0: Boot Sector END
;*******************************


