/**
 * @file main.c
 * @brief all kernel operations happen from this file
 */

#include "attributes.h"
#include "vga.h"
#include "print.h"
#include "types.h"
#include "memory_map.h"

void panic(void);

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

    MemoryMap* mM = MM_BASE;
    if (init_memory_map(mM)) {
        panic();
    }

    print_memory_map();

    //there is no interupts/inputs, therefore no loop yet
    panic();
}

NORETURN void panic(void) {
    while (true) {
        asm ("hlt");
    }
}
