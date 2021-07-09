/**
 * @file vga.h
 * @brief vga function definitions and macros
 */

#pragma once

#include "types.h"

#define VGA_BASE (u16*)0xB8000 ///< base address of text mode vga memory
#define VGA_LIMIT (u16*)0xBFD00 ///< highest address of text mode vga memory
#define VGA_WIDTH 80 ///< width of text mode vga memory

/// text mode vga colours
typedef enum {
    BLACK,
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    BROWN,
    LIGHTGRAY,
    DARKGRAY,
    LIGHTBLUE,
    LIGHTGREEN,
    LIGHTCYAN,
    LIGHTRED,
    PINK,
    YELLOW,
    WHITE
} Colours;

/**
 * @brief contains cursor x and y position
 */
typedef struct {
    u8 x; ///< x position
    u8 y; ///< y position
} XY;

void show_cursor(u8 scanline_start, u8 scanline_end);
void hide_cursor(void);
u16 get_cursor_pos(void);
void set_cursor_pos(u16 pos);
XY cursor_pos_to_xy(u16 pos);
u16 xy_to_cursor_pos(XY xy);
void write_char(u8 c, u8 front_colour, u8 back_colour, u16* adr);
void clear_screen(void);
