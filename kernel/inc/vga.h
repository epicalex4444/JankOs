#ifndef VGA_H
#define VGA_H

#include "types.h"

#define VGA_BASE (u16*)0xB8000
#define VGA_LIMIT (u16*)0xBFD00
#define VGA_WIDTH 80

#define BLACK      0
#define BLUE       1
#define GREEN      2
#define CYAN       3
#define RED        4
#define MAGENTA    5
#define BROWN      6
#define LIGHTGRAY  7
#define DARKGRAY   8
#define LIGHTBLUE  9
#define LIGHTGREEN 10
#define LIGHTCYAN  11
#define LIGHTRED   12
#define PINK       13
#define YELLOW     14
#define WHITE      15

typedef struct {
    u8 x;
    u8 y;
} XY;

void show_cursor(u8 scanline_start, u8 scanline_end);
void hide_cursor(void);
u16 get_cursor_pos(void);
void set_cursor_pos(u16 pos);
XY cursor_pos_to_xy(u16 pos);
u16 xy_to_cursor_pos(XY xy);
void write_char(u8 c, u8 front_colour, u8 back_colour, u16* adr);
void clear_screen(void);

#endif
