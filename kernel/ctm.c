// ctm.c

//////////////////////////////////////
//
// VGA-compatible text mode
//
//////////////////////////////////////

#define CTM_NULL                  '\0'

#define CTM_VRAM_ADDRESS          0x000B8000
#define CTM_WIDTH                 80
#define CTM_HEIGHT                25

#define CTM_COLOR_BLACK           0x0
#define CTM_COLOR_BLUE            0x1
#define CTM_COLOR_GREEN           0x2
#define CTM_COLOR_CYAN            0x3
#define CTM_COLOR_RED             0x4
#define CTM_COLOR_MAGENTA         0x5
#define CTM_COLOR_BROWN           0x6
#define CTM_COLOR_LIGHTGRAY       0x7
#define CTM_COLOR_DARKGRAY        0x8
#define CTM_COLOR_LIGHTBLUE       0x9
#define CTM_COLOR_LIGHTGREEN      0xa
#define CTM_COLOR_LIGHTCYAN       0xb
#define CTM_COLOR_LIGHTRED        0xc
#define CTM_COLOR_LIGHTMAGENTA    0xd
#define CTM_COLOR_LIGHTBROWN      0xe
#define CTM_COLOR_WHITE           0xf

#define CTM_ASCII_CODE_LF         0x0a
#define CTM_ASCII_CODE_CR         0x0d
#define CTM_ASCII_CODE_SP         0x20

#define CTM_BUFFER_MAX            16

typedef struct {
  unsigned char x;
  unsigned char y;
} ctm_point;

typedef struct {
  unsigned char width;
  unsigned char height;
} ctm_size;

typedef struct {
  ctm_point point;
  ctm_size size;
} ctm_frame;

typedef struct {
  ctm_frame screen_frame;
  unsigned char fore_color;
  unsigned char back_color;
  char is_show_cursor;
  int z;
  unsigned short *pointer;
} ctm_buffer;

typedef struct {
  ctm_buffer *buffers;
  ctm_buffer *current_buffer;
  unsigned char buffer_count;
} ctm_driver;

// temp
ctm_point ctm_current_point;


void ctm_init_buffer(ctm_buffer *buffer)
{
  buffer->z = 0;
}

ctm_driver *ctm_alloc_driver(ctm_driver *driver)
{
  driver = (ctm_driver*)0x7c00;
  return driver;
}

void ctm_init_driver(ctm_driver *driver)
{
  driver->buffers = CTM_NULL;
  driver->current_buffer = CTM_NULL;
  driver->buffer_count = 0;
}

ctm_buffer *ctm_create_buffer(ctm_driver *driver)
{
  if (driver->buffer_count == 255) return CTM_NULL;

  ctm_buffer *buffer = CTM_NULL;
  buffer = (ctm_buffer*)driver + sizeof(ctm_driver);
  buffer += (driver->buffer_count * sizeof(ctm_buffer));
  ctm_init_buffer(buffer);
  return buffer;
}

void ctm_fill_char(char c, unsigned char fore_color, unsigned char back_color)
{
  unsigned short *vram_text_mode; // unsigned short (2byte) == TextMode memory size
  unsigned short color;
  vram_text_mode = (unsigned short *)CTM_VRAM_ADDRESS;
  color = ( back_color << 4) | (fore_color & 0x0F);
  int i = 0;
  for (i = 0; i < CTM_WIDTH * CTM_HEIGHT; i++) {
    *vram_text_mode = ( color << 8 ) | ' ';
    vram_text_mode++;
  }
}

void ctm_fill(unsigned char back_color)
{
  ctm_fill_char(' ', 0x07, back_color);
}

void ctm_cls()
{
  ctm_fill(0x00);
}

void ctm_set_point(unsigned char x, unsigned char y)
{
  ctm_current_point.x = x;
  ctm_current_point.y = y;
}

void ctm_add_point(unsigned char dx, unsigned char dy)
{
  ctm_current_point.x += dx;
  if (ctm_current_point.x >= CTM_WIDTH) {
    ctm_current_point.x -= CTM_WIDTH;
    dy++;
  }
  ctm_current_point.y += dy;
}

void ctm_put_char_impl(char c, unsigned char fore_color, unsigned char back_color)
{
  unsigned short *vram_text_mode; // unsigned short (2byte) == TextMode memory size
  unsigned short color;
  vram_text_mode = (unsigned short *)CTM_VRAM_ADDRESS;
  color = (back_color << 4) | (fore_color & 0x0F);
  vram_text_mode += ctm_current_point.x + ctm_current_point.y * CTM_WIDTH;
  *vram_text_mode = (color << 8) | c;
  ctm_add_point(1, 0);
}

void ctm_put_char(char c, unsigned char fore_color, unsigned char back_color)
{
  switch(c) {
    case CTM_ASCII_CODE_LF:
      ctm_add_point(0, 1);
      break;
    case CTM_ASCII_CODE_CR:
      ctm_set_point(0, ctm_current_point.y);
      break;
    default:
      ctm_put_char_impl(c, fore_color, back_color);
      break;
  }
}

void ctm_puts(char *str)
{
  while(*str != '\0')
  {
    ctm_put_char(*str, CTM_COLOR_WHITE, CTM_COLOR_BLUE);
    str++;
  }
}

void ctm_put_int_base(int n, int base, int digits)
{
  int i, digit, pn;
  unsigned char c;
  for (i = digits; i >= 0; i--) {
    pn = kmath_pow(base, i);
    digit = n / pn;
    c = (unsigned char)digit + 0x30;
    if (c > 0x39) c += 0x07;
    ctm_put_char_impl(c, CTM_COLOR_WHITE, CTM_COLOR_BLUE);
    n -= digit * pn;
  }
}

void ctm_put_int(int n)
{
  int digits = kmath_sqrt(n, 10);
  ctm_put_int_base(n, 10, digits);
}

void ctm_put_byte_impl(unsigned char c)
{
  ctm_put_int_base((int)c, 16, 1);
}

void ctm_put_byte(unsigned char c)
{
  ctm_puts("0x");
  ctm_put_byte_impl(c);
}

void ctm_put_word(unsigned short i)
{
  ctm_puts("0x");
  ctm_put_byte_impl((unsigned char) (i >> 8));
  ctm_put_byte_impl((unsigned char) i & 0x00ff);
}

void ctm_put_dword(int i)
{
  ctm_puts("0x");
  ctm_put_byte_impl((unsigned char) (i >> 24));
  ctm_put_byte_impl((unsigned char) (i >> 16));
  ctm_put_byte_impl((unsigned char) (i >> 8));
  ctm_put_byte_impl((unsigned char) i & 0xff);
}

void ctm_put_int_bit(int n)
{
  ctm_put_int_base(n, 2, 16);
  ctm_puts("b");
}

void ctm_put_pointer(void *p)
{
  ctm_put_dword((int)p);
}


