[BITS 32]
ORG 0x00100000
      MOV   EAX, 0x00000741
      MOV   EBX, 0x000B8000
      MOV   [EBX], EAX
      HLT
