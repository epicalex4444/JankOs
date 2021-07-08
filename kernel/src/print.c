#include "print.h"
#include "vga.h"

i16 str_len(i8* str) {
    i16 len = 0;
    while (*str != 0) {
        ++str;
        ++len;
    }
    return len;
}

//string have to be null terminated
//returns error if it would have written past video memory
bool print_string(i8* str) {
    u16* adr = VGA_BASE + get_cursor_pos();
    u16 len = str_len(str);

    //disallow writing past video memory
    if (adr + len - 1> VGA_LIMIT) {
        return true;
    }

    while (*str != 0) {
        write_char(*str, WHITE, BLACK, adr);
        ++str;
        ++adr;
    }

    //if there is no extra space for the cursor it is put at 0, 0
    if (adr + len - 1== VGA_LIMIT) {
        set_cursor_pos(0);
    } else {
        set_cursor_pos(len);
    }

    return false;
}
