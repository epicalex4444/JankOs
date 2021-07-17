/**
 * @file vga.c
 * @brief vga text mode driver
 */

#include "vga.h"
#include "io.h"

/**
 * @brief makes the cursor visible
 * @param scanline_start highest pixel of the cursor
 * @param scanline_end lowest pixel of the cursor
 * @details scanline goes from 0 to 15(highest to lowest)
 */
void show_cursor(u8 scanline_start, u8 scanline_end) {
    outb(0x3D4, 0x0A);
    outb(0x3D5, (inb(0x3D5) & 0xC0) | scanline_start);
    outb(0x3D4, 0x0B);
    outb(0x3D5, (inb(0x3D5) & 0xE0) | scanline_end);
}

/// makes the cursor invisible
void hide_cursor(void) {
    outb(0x3D4, 0x0A);
    outb(0x3D5, 0x20);
}

/**
 * @brief gets the cursor position
 * @return the cursor position in y * VGA_WIDTH + x format
 */
u16 get_cursor_pos(void) {
    u16 pos = 0;
    outb(0x3D4, 0x0F);
    pos |= inb(0x3D5);
    outb(0x3D4, 0x0E);
    pos |= ((u16)inb(0x3D5)) << 8;
    return pos;
}

/**
 * @brief sets the cursors position
 * @param pos cursor position in y * VGA_WIDTH + x format
 */
void set_cursor_pos(u16 pos) {
	outb(0x3D4, 0x0F);
	outb(0x3D5, (u8)(pos & 0xFF));
	outb(0x3D4, 0x0E);
	outb(0x3D5, (u8)((pos >> 8) & 0xFF));
}

/**
 * @brief converts y * VGA_WIDTH + x format to x and y
 * @param pos cursor position in y * VGA_WIDTH + x format
 * @return cursor x and y in a struct
 */
XY cursor_pos_to_xy(u16 pos) {
    XY xy;
    xy.x = pos % VGA_WIDTH;
    xy.y = pos / VGA_WIDTH;
    return xy;
}

/**
 * @brief converts x and y format to y * VGA_WIDTH + x
 * @param xy cursor x and y in a struct
 * @return cursor position in y * VGA_WIDTH + x format
 */
u16 xy_to_cursor_pos(XY xy) { 
    return (u16)(xy.y * VGA_WIDTH + xy.x);
}

/**
 * @brief writes a charecter to the screen
 * @param c ascii code of a char
 * @param front_colour foreground colour
 * @param back_colour background colour
 * @param pos y * VGA_WIDTH + x position to write the charecter
 * @details This function can write to arbitrary 
 *          memory and needs to be used carefully.
 */
void write_char(u8 c, u8 front_colour, u8 back_colour, u16 pos) {
    *(VGA_BASE + pos) = ((u16)front_colour << 8) + ((u16)back_colour << 4) + (u16)c;
}

/// writes black background, white text, null char into every video memory entry
void clear_screen(void) {
    u64* adr = (u64*)VGA_BASE;
    u64 val = 0x0F200F200F200F20;
    for (u16 i = 0; i < 500; ++i) {
        *adr = val;
        ++adr;
    }
}

/**
 * @brief initialises vga
 * @details clears screen, sets cursor to 0,
 *          sets cursor to be visible and be 2 pixels thick
 */
void init_vga() {
    clear_screen();
    set_cursor_pos(0);
    show_cursor(14, 15);
}
