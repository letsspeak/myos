// kernel.c

#include "kmath.c"
#include "ctm.c"
#include "gdt.c"
#include "idt.c"
#include "kstdlib.c"
#include "memory.c"

int main(void) __attribute__((section(".text.main")));

//extern char _text_start;
//extern char _text_end;
//extern char _bss_start;
//extern char _bss_end;
//
//unsigned int _TEXT_START;
//unsigned int _TEXT_END;
//unsigned int _BSS_START;
//unsigned int _BSS_END;

int main(void)
{
  // TODO : clear BSS memory
//  initBSS(_BSS_START, _BSS_END - _BSS_START);
//  _TEXT_START   = (unsigned int)&_text_start;
//  _TEXT_END     = (unsigned int)&_text_end;
//  _BSS_START    = (unsigned int)&_bss_start;
//  _BSS_END      = (unsigned int)&_bss_end;


//  ctm_driver *ctm;
//  ctm = ctm_alloc_driver(ctm);
//  ctm_init_driver(ctm);
//
//  ctm_buffer *buf = ctm_create_buffer(ctm);

//  setup_idtr();
  ctm_cls();
  ctm_fill(CTM_COLOR_BLUE);

  ctm_set_point(1, 1);
  ctm_puts("Welcome to myos kernel!");

  ctm_set_point(1, 3);
  ctm_puts("sizeof(int) = ");
  ctm_put_int(sizeof(int));

  ctm_set_point(1, 4);
  ctm_puts("sizeof(char) = ");
  ctm_put_int(sizeof(char));

  ctm_set_point(1, 5);
  ctm_puts("sizeof(long) = ");
  ctm_put_int(sizeof(long));

  ctm_set_point(1, 6);
  ctm_puts("sizeof(short) = ");
  ctm_put_int(sizeof(short));

  ctm_set_point(1, 7);
  ctm_puts("sizeof(void*) = ");
  ctm_put_int(sizeof(void*));

  void *p = (void *)0x12345678;
  ctm_set_point(1, 10);
  ctm_put_pointer(p);

  ctm_set_point(1, 11);
  ctm_put_byte((unsigned char)0x00);

  ctm_set_point(1, 12);
  ctm_put_word((unsigned short)0x0003);

  ctm_set_point(1, 13);
  ctm_put_dword((int)0x00123002);

  ctm_set_point(1, 20);
  setup_gdt();

//  ctm_put_int(12345);
//  ctm_put_int(98765);
//  ctm_put_int_hex(0x00130f);
//  ctm_put_int_bit(0x00130f);

  for (;;)
  {
  }
  return 0;
}
