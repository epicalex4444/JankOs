/**
 * @file print.c
 * @brief low level vga text mode printing
 */

#include "print.h"
#include "vga.h"

/**
 * @brief finds the length of a null terminated string
 * @param str null terminatd string
 * @return the length of the string
 */
i16 str_len(i8* str) {
    i16 len = 0;
    while (*str != 0) {
        ++str;
        ++len;
    }
    return len;
}

/**
 * @brief prints a null terminated string
 * @param str null terminated string
 * @return true on error, false on success
 * @details Starts print from the cursor location.
 *          Cursor position is updated to be after the string.
 *          Unless at the very end where it is sent back to 0,0.
 *          This function is unable to write outside of video memory.
 */
bool print_string(i8* str) {
    u16* adr = VGA_BASE + get_cursor_pos();
    u16 len = str_len(str);

    if (adr + len - 1 > VGA_LIMIT) {
        return true;
    }

    while (*str != 0) {
        write_char(*str, WHITE, BLACK, adr);
        ++str;
        ++adr;
    }

    if (adr + len - 1 == VGA_LIMIT) {
        set_cursor_pos(0);
    } else {
        set_cursor_pos(len);
    }

    return false;
}
