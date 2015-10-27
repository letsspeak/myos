// idt.c

// Interrupt Descriptor Table


// Task Gate Descriptor
//     0 - 15 : <Unused>
//    16 - 31 : TSS Segment Selector
//    32 - 39 : <Unused>
//    40      : 1
//    41      : 0
//    42      : 1
//    43      : 0
//    44      : 0
//    45 - 46 : DPL
//    47      : P
//    48 - 63 : <Unused>

// Interrupt Gate Descriptor
//     0 - 15 : Offset 15:0
//    16 - 31 : Segment Selector (Normally ring0 => Code Descriptor 0x08)
//    32 - 36 : <Unused>
//    37      : 0
//    38      : 0
//    39      : 0
//    40      : 0
//    41      : 1
//    42      : 1
//    43      : D (Gate Size: 0 for 16bit, 1 for 32bit)
//    44      : 0
//    45 - 46 : DPL
//    47      : P
//    48 - 63 : Offset 31:16

// Trap  Gate Descriptor
//     0 - 15 : Offset 15:0
//    16 - 31 : Segment Selector (Normally ring0 => Code Descriptor 0x08)
//    32 - 36 : <Unused>
//    37      : 0
//    38      : 0
//    39      : 0
//    40      : 1
//    41      : 1
//    42      : 1
//    43      : D
//    44      : 0
//    45 - 46 : DPL
//    47      : P
//    48 - 63 : Offset 31:16


// Definition of Interrupt Gate Descriptor Flags
//  bit number    description
//  0...4         interrupt gate              : 01110b = 32bit descriptor
//                                            : 00110b = 16bit descriptor
//                task gate                   : must be 00101b
//                trap gate                   : 01111b = 32bit descriptor
//  5...6         descriptor privilege level  : ring0 = 00b
//                                            : ring1 = 01b
//                                            : ring2 = 10b
//                                            : ring3 = 11b
//  7             present bit                 : Segment is present


#define IDT_FLAGS_INTERRUPT_GATE_16BIT        0x06
#define IDT_FLAGS_INTERRUPT_GATE_32BIT        0x0e
#define IDT_FLAGS_TASK_GATE                   0x05
#define IDT_FLAGS_TRAP_GATE                   0x0f
#define IDT_FLAGS_CALL_GATE                   0x0c
#define IDT_FLAGS_DPL_LV0                     0x00
#define IDT_FLAGS_DPL_LV1                     0x20
#define IDT_FLAGS_DPL_LV2                     0x40
#define IDT_FLAGS_DPL_LV3                     0x60
#define IDT_FLAGS_PRESENT                     0x80

#define IDT_INTERRUPT_SELECTOR                0x08

#define NUM_IDT 256

typedef struct
{
  unsigned short base_lo;
  unsigned short segment_selector;
  unsigned char reserved;
  unsigned char flags;
  unsigned short base_hi;
} __attribute__ ((packed)) gate_descriptor;

gate_descriptor idt_descriptors[NUM_IDT];

typedef struct
{
  unsigned short size;
  gate_descriptor *base;
} __attribute__ ((packed)) idt_struct;

idt_struct idtr;

void setup_gate_descriptor(int id, int base, unsigned short segment_selector, unsigned char flags)
{
  idt_descriptors[id].base_lo = (unsigned short)(base & 0x0000ffff);
  idt_descriptors[id].segment_selector = segment_selector;
  idt_descriptors[id].reserved = 0x00;
  idt_descriptors[id].flags = flags;
  idt_descriptors[id].base_hi = (unsigned short)(base & 0xffff0000 >> 16);
}

void setup_interrupt_gate(int id, void *interrupt_handler)
{
  setup_gate_descriptor(id, (int)interrupt_handler,
      IDT_INTERRUPT_SELECTOR, 
      IDT_FLAGS_PRESENT | IDT_FLAGS_INTERRUPT_GATE_32BIT);
}

#define load_idt() ({ __asm__ __volatile__ ("lidt idtr"); })

void setup_idtr(void)
{
  idtr.size = NUM_IDT * sizeof (gate_descriptor);
  idtr.base = (gate_descriptor*)idt_descriptors;
  load_idt();
}



