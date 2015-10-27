// kernel.c

#include "gdt.c"
#include "idt.c"
#include "kstdlib.c"
#include "kmath.c"
#include "memory.c"
#include "ctm.c"

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
  setup_gdtr();

  ctm_cls();
  ctm_fill(CTM_COLOR_BLUE);

  ctm_set_point(0, 0);
  ctm_put_char('B', 0x07, 0x00);

  ctm_set_point(0, 10);
  ctm_puts("Welcome\r\n to myos kernel!");

  ctm_set_point(10, 20);
  ctm_puts("Welcome to myos kernel!22222");

  ctm_put_int(12345);
  ctm_put_int(98765);
  ctm_put_int_hex(0x00130f);
  ctm_put_int_bit(0x00130f);

  for (;;)
  {
  }
  return 0;
}
