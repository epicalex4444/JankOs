/**
 * @file print.c
 * @brief low level vga text mode printing
 */

#include "print.h"
#include "string.h"

u16 newline(u16 pos) {
    pos = pos / VGA_WIDTH * VGA_WIDTH + VGA_WIDTH;
    if (pos >= POS_MAX) {
        return 0;
    }
    return pos;
}

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
        if (*str == '\n') {
            pos = newline(pos);
            ++str;
            continue;
        }
        write_char(*str, WHITE, BLACK, pos);
        ++str;
        pos = NEXT_POS(pos);
    }

    set_cursor_pos(pos);
}

/**
 * @brief prints out hex of a data type
 * @param num void* to print out as hex
 * @param size how many bits the data type is
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_hex(void* num, u8 size) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos);
    pos = NEXT_POS(pos);
    write_char('x', WHITE, BLACK, pos);
    pos = NEXT_POS(pos);

    switch (size) {
        case 8:
            print_hex_8(*((u8*)num), pos);
            break;
        case 16:
            print_hex_16(*((u16*)num), pos);
            break;
        case 32:
            print_hex_32(*((u32*)num), pos);
            break;
        case 64:
            print_hex_64(*((u64*)num), pos);
            break;
    }
}

/**
 * @brief prints out u8 as hex
 * @param num value to print a hex
 * @param pos position to start printing from
 * @details Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_hex_8(u8 num, u16 pos) {
    u8 mask = 0xF0;
    u8 shift = 4;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        pos = NEXT_POS(pos);
    }
    set_cursor_pos(pos);
}

/**
 * @brief prints out u16 as hex
 * @param num value to print a hex
 * @param pos position to start printing from
 * @details Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_hex_16(u16 num, u16 pos) {
    u16 mask = 0xF000;
    u8 shift = 12;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        pos = NEXT_POS(pos);
    }
    set_cursor_pos(pos);
}

/**
 * @brief prints out u32 as hex
 * @param num value to print a hex
 * @param pos position to start printing from
 * @details Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_hex_32(u32 num, u16 pos) {
    u32 mask = 0xF0000000;
    u8 shift = 28;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        pos = NEXT_POS(pos);
    }
    set_cursor_pos(pos);
}

/**
 * @brief prints out u64 as hex
 * @param num value to print a hex
 * @param pos position to start printing from
 * @details Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_hex_64(u64 num, u16 pos) {
    u64 mask = 0xF000000000000000;
    u8 shift = 60;
    while (mask != 0) {
        write_char(NUM_TO_HEX((mask & num) >> shift), WHITE, BLACK, pos);
        shift -= 4;
        mask >>= 4;
        pos = NEXT_POS(pos);
    }
    set_cursor_pos(pos);
}

/**
 * @brief prints out hex of a data type
 * @param num void* to print out as binary
 * @param size how many bits the data type is
 * @details Starts at cursor position.
 *          Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_binary(void* num, u8 size) {
    u16 pos = get_cursor_pos();
    write_char('0', WHITE, BLACK, pos);
    pos = NEXT_POS(pos);
    write_char('b', WHITE, BLACK, pos);
    pos = NEXT_POS(pos);

    switch (size) {
        case 8:
            print_binary_8(*((u8*)num), pos);
            break;
        case 16:
            print_binary_16(*((u16*)num), pos);
            break;
        case 32:
            print_binary_32(*((u32*)num), pos);
            break;
        case 64:
            print_binary_64(*((u64*)num), pos);
            break;
    }
}

/**
 * @brief prints out u8 as binary
 * @param num value to print a binary
 * @param pos position to start printing from
 * @details Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_binary_8(u8 num, u16 pos) {
    u8 mask = 0x80;
    while (mask != 0) {
        if (mask & num) {
            write_char('1', WHITE, BLACK, pos);
        } else {
            write_char('0', WHITE, BLACK, pos);
        }
        mask >>= 1;
        pos = NEXT_POS(pos);
    }
    set_cursor_pos(pos);
}

/**
 * @brief prints out u16 as binary
 * @param num value to print a binary
 * @param pos position to start printing from
 * @details Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_binary_16(u16 num, u16 pos) {
    u16 mask = 0x8000;
    while (mask != 0) {
        if (mask & num) {
            write_char('1', WHITE, BLACK, pos);
        } else {
            write_char('0', WHITE, BLACK, pos);
        }
        mask >>= 1;
        pos = NEXT_POS(pos);
    }
    set_cursor_pos(pos);
}

/**
 * @brief prints out u32 as binary
 * @param num value to print a binary
 * @param pos position to start printing from
 * @details Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_binary_32(u32 num, u16 pos) {
    u32 mask = 0x80000000;
    while (mask != 0) {
        if (mask & num) {
            write_char('1', WHITE, BLACK, pos);
        } else {
            write_char('0', WHITE, BLACK, pos);
        }
        mask >>= 1;
        pos = NEXT_POS(pos);
    }
    set_cursor_pos(pos);
}

/**
 * @brief prints out u64 as binary
 * @param num value to print a binary
 * @param pos position to start printing from
 * @details Cursor is updated to be after the last char,
 *          wraps around to start if it gets to the end.
 */
void print_binary_64(u64 num, u16 pos) {
    u64 mask = 0x8000000000000000;
    while (mask != 0) {
        if (mask & num) {
            write_char('1', WHITE, BLACK, pos);
        } else {
            write_char('0', WHITE, BLACK, pos);
        }
        mask >>= 1;
        pos = NEXT_POS(pos);
    }
    set_cursor_pos(pos);
}
