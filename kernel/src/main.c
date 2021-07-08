#include "attributes.h"
#include "vga.h"

NORETURN void _start(void) {
    //setup vga
    //TODO - make sure tons of other settings are correct such as text mode, and blinking disabled
    clear_screen();
    set_cursor(0);
    show_cursor(14, 15);
    while (1);
}
