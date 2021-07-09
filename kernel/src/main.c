/**
 * @file main.c
 * @brief all kernel operations happen from this file
 */

#include "attributes.h"
#include "vga.h"
#include "print.h"
#include "types.h"

/**
 * @brief kernel entry point
 * @details This functions is called from kernel_entry.asm and 
 *          marks the start of kernel operation. This function
 *          is designed to not be returned from and instead calls
 *          functions from other files.
 */
NORETURN void _start(void) {
    //setup vga
    clear_screen();
    set_cursor_pos(0);
    show_cursor(14, 15);
    
    i8 str[] = "Hello, World!";
    print_string(str);

    while (true);
}
