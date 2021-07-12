/**
 * @file print.c
 * @brief low level vga text mode printing
 */

#include "print.h"
#include "vga.h"

/**
 * @brief prints a null terminated string
 * @param str null terminated string
 * @return true on error, false on success
 * @details Starts print from the cursor location.
 *          Cursor position is updated to be after the string.
 *          If the string is too long to fit in the remaining,
 *          it wraps around to the start.
 */
void print_string(i8* str) {
    u16 pos = get_cursor_pos();

    while (*str != 0) {
        write_char(*str, WHITE, BLACK, VGA_BASE + pos);
        ++str;
        if (pos == POS_MAX) {
            pos = 0;
        } else {
            ++pos;
        }
    }

    set_cursor_pos(pos);
}
