/**
 * @file memory.h
 * @brief memory function definitions
 */

#pragma once

#include "types.h"

//parsed memory map is made at 0x5000 then moved to 0x500 replacing the E820 memory map
#define E820_COUNT (u16*)0x5000 ///< pointer to E820 memory map entry counter
#define E820_ENTRIES (u64*)0x5002 ///< E820 memory map base address
#define MM_BASE (MemoryMap*)0x500 ///< base of memory map
#define MM_ENTRIES (MemoryMapEntry*)0x510 ///< base of memory map

/// memory type enum
typedef enum {
    FREE = 1,
    RESERVED,
    ACPI_RECLAMABLE,
    ACPI_NVMS,
    BAD
} MemoryType;

/// entry for memory map
typedef struct {
    u64 start;  ///< start address of entry
    u64 length; ///< length of entry
    u32 type;   ///< type of entry
    u32 acpi;   ///< acpi extended info
} MemoryMapEntry;

/// full map of physical memory
typedef struct {
    u16 size; ///< amount of entries
    MemoryMapEntry* entries; ///< memory map entries
} MemoryMap;

bool init_memory_map(MemoryMap* mM);
void print_memory_map(void);
