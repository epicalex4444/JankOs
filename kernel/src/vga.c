#include "vga.h"
#include "io.h"

//scanline sets the size of the cursor 0 is the top, 15 is the bottom(usually)
void show_cursor(u8 scanline_start, u8 scanline_end) {
    outb(0x3D4, 0x0A);
    outb(0x3D5, (inb(0x3D5) & 0xC0) | scanline_start);
    outb(0x3D4, 0x0B);
    outb(0x3D5, (inb(0x3D5) & 0xE0) | scanline_end);
}

void hide_cursor(void) {
    outb(0x3D4, 0x0A);
    outb(0x3D5, 0x20);
}

u16 get_cursor(void) {
    u16 pos = 0;
    outb(0x3D4, 0x0F);
    pos |= inb(0x3D5);
    outb(0x3D4, 0x0E);
    pos |= ((u16)inb(0x3D5)) << 8;
    return pos;
}

XY cursor_pos_to_xy(u16 pos) {
    XY xy;
    xy.x = pos % VGA_WIDTH;
    xy.y = pos / VGA_WIDTH;
    return xy;
}

u16 xy_to_cursor_pos(XY xy) { 
    return (u16)(xy.y * VGA_WIDTH + xy.x);
}

void set_cursor(u16 pos) {
	outb(0x3D4, 0x0F);
	outb(0x3D5, (u8)(pos & 0xFF));
	outb(0x3D4, 0x0E);
	outb(0x3D5, (u8)((pos >> 8) & 0xFF));
}

//this function has the potential to write outside of video memory
//and thus it needs to be used carefully
void write_char(u8 c, u8 front_colour, u8 back_colour, u16* adr) {
    *adr = ((u16)front_colour << 8) + ((u16)back_colour << 4) + (u16)c;
}

void clear_screen(void) {
    u64* adr = (u64*)VGA_BASE;
    u64 val = 0x0F200F200F200F20;
    for (u16 i = 0; i < 500; ++i) {
        *adr = val;
        ++adr;
    }
}
