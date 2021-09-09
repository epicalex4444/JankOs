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

//error id's
typedef enum {
    NONE,
    PARSE_MM,
} Error;

//error messages
i8 parse_mm[] = "couldn't parse memory map\n";

/**
 * @brief kernel entry point
 * @details This functions is called from kernel_entry.asm and 
 *          marks the start of kernel operation. This function
 *          is designed to not be returned from and instead calls
 *          functions from other files.
 */
NORETURN void start_kernel(void) {
    u8 error = NONE;

    init_vga();
    init_gdt();

    if (init_memory_map()) {
        error = PARSE_MM;
        goto error_label;
    }

    print_memory_map();

    //kernel cannot continue with any of these errors occur
    //prints out error message and exits
    error_label:
    switch (error) {
        case PARSE_MM:
            print_string(parse_mm);
    }

    //indefinate hang
    //hlt stops cpu execution so isn't busy waiting wasting power
    for(;;) {
        asm ("hlt");
    }
}
