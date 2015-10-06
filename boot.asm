;/*****************************
; File:boot.asm
; Description: MyOS Bootloader
;****************************/
[BITS 16]

ORG       0x7C00

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
; Read Sectors
          MOV     AX, 2000
          CALL    ReadSectors
          HLT

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

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; DisplayMessage
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

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; ReadSectors
; Read Sectors
;
; input AX: logical sector number (LBA)
;
; セクタ:512バイト
; シリンダ: 18セクタ (SecPerTrack)
; ヘッド: 80シリンダ
; 総セクタ: 2 x 80 x 18 = 2880 ( 0x0E04 )
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
ReadSectors:
          CALL LBA2CHS                    ; 論理セクタを物理セクタに変換
          MOV AH, 0x02                    ; セクタ読み込みモード
          MOV AL, 0x01                    ; 1つのセクタだけ読み込み
          MOV CH, BYTE [physicalTrack]    ; Track
          MOV CL, BYTE [physicalSector]   ; Sector
          MOV DH, BYTE [physicalHead]     ; Head
          MOV DL, BYTE [BS_DrvNum]        ; Drive
          MOV BX, 0x1000                  ;
          MOV ES, BX                      ; アドレス0x10000から開始するセグメントに読み込みます
          MOV BX, 0x0000                  ; セグメントの最初(オフセット0x0000)に読み込みます。
          INT 0x13                        ; セクタを読み込みます
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

physicalSector  DB 0x00
physicalHead    DB 0x00
physicalTrack   DB 0x00

;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
;
; Data Section
;
;/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

LineFeedCode                DB 0x0D, 0x0A, 0x00
ImageName                   DB "MyOS Boot Loader", 0x00
ResetFloppyDriveSuccess     DB "Reset Floppy Drive.....Success", 0x00
ResetFloppyDriveFail        DB "Reset Floppy Drive.....Fail", 0x00

TIMES 510 - ($ - $$) DB 0

DW 0xAA55

