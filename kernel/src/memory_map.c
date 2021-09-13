/**
 * @file memory_map.c
 * @brief memory function declarations
 */

#include "memory_map.h"
#include "print.h"
#include "vga.h"

/**
 * @brief parses the memory map and allocates it to a struct
 * @return if there was an error
 */
bool init_memory_map() {
    //check there is an entry
    if (!*E820_COUNT) {
        return true;
    }

    //assign E820 and mM from static address values
    u64* E820 = E820_ENTRIES;
    MemoryMap* mM = MM_BASE;
    mM->entries = MM_ENTRIES;

    //fill mM->entries
    for (mM->size = 0; mM->size < (u64)(*E820_COUNT); ++mM->size, E820 += 3) {
        //remove length 0 entries
        if (!*(E820 + 1)) {
            continue;
        }

        //remove entries with acpi ignore bit unset
        if (!(*((u32*)(E820 + 2) + 1) & 1)) {
            continue;
        }

        //assign values from the E820 table
        mM->entries[mM->size].start = *E820;
        mM->entries[mM->size].length = *(E820 + 1);
        mM->entries[mM->size].type = *(u32*)(E820 + 2);
        mM->entries[mM->size].acpi = *((u32*)(E820 + 2) + 1);
    }

    //bubble sort entries
    MemoryMapEntry temp;
    for (u16 i = 0; i < mM->size; ++i) {
        for (u16 j = i - 1; j < mM->size; ++j) {
            if (mM->entries[i].start < mM->entries[j].start) {
                temp = mM->entries[j];
                mM->entries[j] = mM->entries[i];
                mM->entries[i] = temp;
            }
        }
    }

    bool freeEntry = false;

    //more parsing/checking of the memory map
    for (i16 i = mM->size - 2; i >= 0; --i) {
        //check for overlaps
        if (mM->entries[i].start + mM->entries[i].length > mM->entries[i + 1].start) {
            return true;
        }

        //keeps track if there is a free entry
        if (mM->entries[i].type == FREE) {
            freeEntry = true;
        }

        //if the memory is non volotile, set the type to bad
        //TODO figure out if the memory is usable
        if ((mM->entries[mM->size].acpi & 2) == 2) {
            mM->entries[mM->size].type = BAD;
        }

        //TODO reclaim acpi reclamable

        //reserve memory under 0x100000
        //this memory space is used for many important things that are often considered free
        if ((mM->entries[i].start < 0x100000) && (mM->entries[i].type == FREE)) {
            if (mM->entries[i].start + mM->entries[i].length <= 0x100000) {
                mM->entries[i].type = RESERVED;
            } else {
                ++mM->size;
                for (u16 j = mM->size; j > i; --j) {
                    mM->entries[j] = mM->entries[j - 1];
                }
                mM->entries[i + 1].start = 0x100000;
                mM->entries[i + 1].length = 0x100000 - mM->entries[i].start;
                mM->entries[i + 1].type = mM->entries[i].type;
                mM->entries[i + 1].acpi = mM->entries[i].acpi;
                mM->entries[i].type = RESERVED;
                mM->entries[i].length = 0x100000 - mM->entries[i].start;
            }
        }

        //combine adjecent memories of the same type and acpi
        if ((mM->entries[i].start + mM->entries[i].length == mM->entries[i + 1].start) && (mM->entries[i].type == mM->entries[i + 1].type) && (mM->entries[i].acpi == mM->entries[i + 1].acpi)) {
            mM->entries[i].length += mM->entries[i + 1].length;
            --mM->size;
            for (u16 j = i + 1; j < mM->size; ++j) {
                mM->entries[j] = mM->entries[j + 1];
            }
        }
    }

    //error if there is no free entry
    return !freeEntry;
}

/// prints the memory map
void print_memory_map(void) {
    u8 seperator[] = "|";

    MemoryMap* mM = MM_BASE;

    print_string((u8*)"Memory Map:\nSize: ");
    print_hex((void*)&(mM->size), 16);
    print_string((u8*)"\nStart             |Length            |Type      |Acpi      \n");

    for (u16 i = 0; i < mM->size; ++i) {
        print_hex((void*)&(mM->entries[i].start), 64);
        print_string(seperator);
        print_hex((void*)&(mM->entries[i].length), 64);
        print_string(seperator);
        print_hex((void*)&(mM->entries[i].type), 32);
        print_string(seperator);
        print_hex((void*)&(mM->entries[i].acpi), 32);
        print_string((u8*)"\n");
    }
}

/// prints the E820 memory map
void print_E820(void) {
    u8 seperator[] = "|";

    u64* E820 = E820_ENTRIES;

    print_string((u8*)"E820 Memory Map:\nSize: ");
    print_hex((void*)E820_COUNT, 16);
    print_string((u8*)"\nStart             |Length            |Type      |Acpi      \n");

    for (u16 i = 0; i < (u16)(*E820_COUNT); ++i, E820 += 3) {
        print_hex((void*)(E820), 64);
        print_string(seperator);
        print_hex((void*)(E820 + 1), 64);
        print_string(seperator);
        print_hex((void*)(u32*)(E820 + 2), 32);
        print_string(seperator);
        print_hex((void*)((u32*)(E820 + 2) + 1), 32);
        print_string((u8*)"\n");
    }
}
