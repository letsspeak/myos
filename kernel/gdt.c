// gdt.c

// Global Descriptor Table

//     0 - 15 : Segment Limit Low 15:00
//    16 - 31 : Base Address Low 15:00
//    32 - 39 : Base Address Mid 23:16
//    40      : Access bit (0:unaccessed, 1:accessed)
//    41      : Read / Write bit
//            : on Data Segment 0:read only, 1:readable writable
//            : on Code Segment 0:execute only, 1:readable executable
//    42      : Direction bit / Conforming bit
//            : on Data Segment(Direction bit)
//            :   0: the segment grows up (normally this)
//            :   1: the segment grows down
//            : on Code Segment(Conforming bit)
//            :   0: Disallow. code in this segment can only be executed from the ring set in privl
//            :   1: Allow. code in this segment can be executed from an equal or lower privilege
//    43      : Executable Bit = Segment Type (0: data sector, 1: code sector)
//    44      : Descriptor Type Flag (0: for system segment, 1: for code segment or data segment)
//    45 - 46 : Descriptor Privilege Level (Hi 3...0 Low)
//    47      : Segment Present Flag (This must be 1 for all valid sectors)
//    48 - 51 : Segment Limit Hi 19:16
//    52      : Available Flag (free use)
//    53      : 0
//    54      : Size bit. (0: for 16 bit protected mode, 1: for 32 bit protected mode)
//    55      : Granularity bit for Segment Limit (0: 1x, 1:4KBx)
//    56 - 63 : Base Address Hi 31:24

#define GDT_NULL_DESCRIPTOR           0
#define GDT_CODE_DESCRIPTOR           1
#define GDT_DATA_DESCRIPTOR           2
#define GDT_TEMP_DESCRIPTOR           3
#define GDT_TASK_CODE_DESCRIPTOR      4
#define GDT_TASK_DATA_DESCRIPTOR      5
#define GDT_KTSS_DESCRIPTOR           6

// for NULL Descriptor
#define GDT_NULL_LIMIT                0x0000
#define GDT_NULL_BASE_LO              0x0000
#define GDT_NULL_BASE_MID             0x00
#define GDT_NULL_FLAGS                0x0000
#define GDT_NULL_BASE_HI              0x00

// for Code Descriptor
#define GDT_CODE_LIMIT                0xffff
#define GDT_CODE_BASE_LO              0x0000
#define GDT_CODE_BASE_MID             0x00
#define GDT_CODE_FLAGS_BL             0x9a
#define GDT_CODE_FLAGS_BH             0xcf
#define GDT_CODE_FLAGS                0xcf9a
#define GDT_CODE_BASE_HI              0x00

// for Data Descriptor
#define GDT_DATA_LIMIT                0xffff
#define GDT_DATA_BASE_LO              0x0000
#define GDT_DATA_BASE_MID             0x00
#define GDT_DATA_FLAGS_BL             0x92
#define GDT_DATA_FLAGS_BH             0xcf
#define GDT_DATA_FLAGS                0xcf92
#define GDT_DATA_BASE_HI              0x00

#define NUM_GDT   3

typedef struct
{
  unsigned short limit_lo;
  unsigned short base_lo;
  unsigned char base_mid;
  unsigned short flags;
  unsigned short base_hi;
} __attribute__ ((packed)) segment_descriptor;

segment_descriptor gdt[NUM_GDT];

typedef struct
{
  unsigned short size;
  unsigned long *base;
} __attribute__ ((packed)) gdt_struct;

gdt_struct gdtr;

void setup_segment_descriptor(void)
{
  // set up NULL Descriptor
  gdt[GDT_NULL_DESCRIPTOR].limit_lo = GDT_NULL_LIMIT;
  gdt[GDT_NULL_DESCRIPTOR].base_lo  = GDT_NULL_BASE_LO;
  gdt[GDT_NULL_DESCRIPTOR].base_mid = GDT_NULL_BASE_MID;
  gdt[GDT_NULL_DESCRIPTOR].flags    = GDT_NULL_FLAGS;
  gdt[GDT_NULL_DESCRIPTOR].base_hi  = GDT_NULL_BASE_HI;

  // set up Code Descriptor
  gdt[GDT_CODE_DESCRIPTOR].limit_lo = GDT_CODE_LIMIT;
  gdt[GDT_CODE_DESCRIPTOR].base_lo  = GDT_CODE_BASE_LO;
  gdt[GDT_CODE_DESCRIPTOR].base_mid = GDT_CODE_BASE_MID;
  gdt[GDT_CODE_DESCRIPTOR].flags    = GDT_CODE_FLAGS;
  gdt[GDT_CODE_DESCRIPTOR].base_hi  = GDT_CODE_BASE_HI;

  // set up Data Descriptor
  gdt[GDT_DATA_DESCRIPTOR].limit_lo = GDT_DATA_LIMIT;
  gdt[GDT_DATA_DESCRIPTOR].base_lo  = GDT_DATA_BASE_LO;
  gdt[GDT_DATA_DESCRIPTOR].base_mid = GDT_DATA_BASE_MID;
  gdt[GDT_DATA_DESCRIPTOR].flags    = GDT_DATA_FLAGS;
  gdt[GDT_DATA_DESCRIPTOR].base_hi  = GDT_DATA_BASE_HI;
}

//#define load_gdt() ({ __asm__ __volatile__ ("lgdt gdtr"); })

void clear_segment_selector()
{
  __asm__ __volatile__ ("mov %ax, 0x10"); 
  __asm__ __volatile__ ("mov %ds, %ax"); 
  __asm__ __volatile__ ("mov %es, %ax"); 
  __asm__ __volatile__ ("mov %fs, %ax"); 
  __asm__ __volatile__ ("mov %gs, %ax"); 
  __asm__ __volatile__ ("mov %ss, %ax"); 
  __asm__ __volatile__ ("jmp 0x08:_flush_seg"); 
  __asm__ __volatile__ ("_flush_seg:");
}

static inline void load_gdt(const struct gdt_struct *dtr)
{
    asm volatile("lgdt %0"::"m" (*dtr));
}

void setup_gdtr(void)
{
  gdtr.size = NUM_GDT * sizeof(segment_descriptor);
  gdtr.base = (unsigned long*)gdt;
  setup_segment_descriptor();
  load_gdt(&gdtr);
//  const gdt_struct *pgdt = &gdtr;
//  asm volatile("lgdt %0"::"m" (&gdtr));
//  __asm__ __volatile__ ("lgdt [gdtr]");
//  asm volatile("lgdt (%0)": "m" (&gdtr));
//  load_gdt();
  clear_segment_selector();
}


