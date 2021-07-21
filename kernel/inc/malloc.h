/**
 * @file malloc.h
 * @brief malloc function definitions
 */

#pragma once

#include "types.h"
#include "memory_map.h"

//overwrites E820 map, since it is now useless
//directly after page tables
#define BITMAP_BASE (BitMap*)0x5000         ///< base of bitmap
#define BITMAP_ENTRIES (BitMapEntry*)0x5010 ///< base of entires pointer

typedef struct {
    u64 start;
    u64 length;
    u8 type;
} BitMapEntry;

typedef struct {
    u64 size;
    BitMapEntry* entries;
} BitMap;

void init_malloc(void);
void* malloc(u64 bytes);
bool free(void* ptr, u64 bytes);
void print_bitmap(void);
