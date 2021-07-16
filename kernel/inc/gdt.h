/**
 * @file gdt.h
 * @brief function declarations for the gdt
 */

#pragma once

#include "types.h"
#include "attributes.h"

typedef struct PACKED {
    u16 limit0;
    u16 base0;
    u8 base1;
    u8 access;
    u8 limit1Flags;
    u8 base2;
} GDTEntry;

typedef struct PACKED {
    GDTEntry null;
    GDTEntry code;
    GDTEntry data;
} GDT;

typedef struct PACKED {
    u16 size;
    u64 offset;
} GDTDescriptor;

NAKED void load_gdt(GDTDescriptor* gdtDescriptor);
void init_gdt(void);
