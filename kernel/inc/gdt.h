/**
 * @file gdt.h
 * @brief function declarations for the gdt
 */

#pragma once

#include "types.h"
#include "attributes.h"

/// gdt entry struct
typedef struct PACKED {
    u16 limit0;     ///< start of limit
    u16 base0;      ///< start of base
    u8 base1;       ///< middle of base
    u8 access;      ///< access flags
    u8 limit1Flags; ///< end of limit and more flags
    u8 base2;       ///< end of base
} GDTEntry;

/// gdt
typedef struct PACKED {
    GDTEntry null; ///< mandatory null entry
    GDTEntry code; ///< code entry
    GDTEntry data; ///< data entry
} GDT;

/// gdt descriptor
typedef struct PACKED {
    u16 size;   ///< size of the gdt
    u64 offset; ///< start address of the gdt
} GDTDescriptor;

NAKED void load_gdt(GDTDescriptor* gdtDescriptor);
void init_gdt(void);
void enter_compatability_mode(void);
void exit_compatability_mode(void);
