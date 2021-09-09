/**
 * @file main.c
 * @brief all kernel operations happen from this file
 */

#include "attributes.h"
#include "vga.h"
#include "print.h"
#include "types.h"
#include "memory_map.h"
#include "gdt.h"

/**
 * @brief kernel entry point
 * @details This functions is called from kernel_entry.asm and 
 *          marks the start of kernel operation. This function
 *          is designed to not be returned from and instead calls
 *          functions from other files.
 */
NORETURN void start_kernel(void) {
    init_vga();
    init_gdt();

    if (init_memory_map()) {
        i8 str[] = "couldn't parse memory map\n";
        print_string(str);
        goto hang;
    }

    print_memory_map();

    hang:
    for(;;) {
        asm ("hlt");
    }
}
