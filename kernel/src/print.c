/**
 * @file print.c
 * @brief low level vga text mode printing
 */

#include "print.h"
#include "vga.h"
#include "string.h"

/**
 * @brief prints a null terminated string
 * @param str null terminated string
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_string(i8* str) {
    u16 pos = get_cursor_pos();

    while (*str != 0) {
        write_char(*str, WHITE, BLACK, pos);
        ++str;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints u8 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_u8_hex(u8 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u8 mask = 0xF0;
    u8 shift = 4;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints u16 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_u16_hex(u16 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u16 mask = 0xF000;
    u8 shift = 12;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints u32 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_u32_hex(u32 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u32 mask = 0xF0000000;
    u8 shift = 28;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints u64 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_u64_hex(u64 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u64 mask = 0xF000000000000000;
    u8 shift = 60;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints i8 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_i8_hex(i8 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u8 mask = 0xF0;
    u8 shift = 4;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints i16 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_i16_hex(i16 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u16 mask = 0xF000;
    u8 shift = 12;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints i32 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_i32_hex(i32 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u32 mask = 0xF0000000;
    u8 shift = 28;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints i64 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_i64_hex(i64 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u64 mask = 0xF000000000000000;
    u8 shift = 60;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints f32 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_f32_hex(f32 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u32 integer = *((u32*)&num);

    u32 mask = 0xF0000000;
    u8 shift = 28;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & integer) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints f64 in hex
 * @param num number that is getting printed
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_f64_hex(f64 num) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos++);
    write_char('x', WHITE, BLACK, pos++);

    u64 integer = *((u64*)&num);

    u64 mask = 0xF000000000000000;
    u8 shift = 60;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & integer) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}
