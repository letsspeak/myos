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

          HLT

TIMES 510 - ($ - $$) DB 0

DW 0xAA55
