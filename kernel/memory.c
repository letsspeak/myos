// memory.c

void initBSS(unsigned int kernel_bss_start, int size)
{
  kmemset( (void*)kernel_bss_start, 0x00, size);
}
