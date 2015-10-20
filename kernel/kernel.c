// kernel.c

//#include "section.h"
//#include "kstdlib.c"
//
//#include "memory.c"
//
//#define VRAM_TEXTMODE     0x000B8000
//
//void displaySample(void)
//{
//  unsigned short *vram_TextMode;
//  vram_TextMode = (unsigned short *)VRAM_TEXTMODE;
//  *vram_TextMode = ( 0x07 << 8 ) | 'A';
//}

int _kernel_entry( void )
{
  unsigned short *vram_TextMode = (unsigned short *)0x000B8000;
  *vram_TextMode = 0x00000741;
  //initBSS(_BSS_START, _BSS_END - _BSS_START);
  //displaySample();
//  for (;;)
//  {
//  }
  return 0;
}
