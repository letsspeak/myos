// kstdlib.c

int a;
void kmemset (void *str, unsigned char c, int size )
{
  unsigned char *ptr = ( unsigned char *)str;
  const unsigned char ch = (const unsigned char)c;
  while (size--)
    *ptr++ = ch;
}

