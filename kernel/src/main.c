#include "attributes.h"
#include "vga.h"
#include "print.h"
#include "types.h"

NORETURN void _start(void) {
    //setup vga
    clear_screen();
    set_cursor_pos(0);
    show_cursor(14, 15);
    
    i8 str[] = "Hello, World!";
    print_string(str);

    while (true);
}
