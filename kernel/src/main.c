#include "attributes.h"
#include "vga.h"
#include "print.h"

NORETURN void _start(void) {
    //setup vga
    //TODO - make sure tons of other settings are correct such as text mode, and blinking disabled
    clear_screen();
    set_cursor_pos(0);
    show_cursor(14, 15);

    i8 str[] = "Hello, World!";
    print_string(str);
    while (1);
}
