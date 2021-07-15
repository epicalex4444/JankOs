/**
 * @file memory.c
 * @brief memory function declarations
 */

#include "memory_map.h"
#include "print.h"
#include "vga.h"

/**
 * @brief parses the memory map and allocates it to a struct
 * @param mM pointer to memory map location
 * @return if there was an error
 */
bool init_memory_map(MemoryMap* mM) {
    //check more than 1 entry
    if (*E820_COUNT <= 1) {
        return true;
    }

    u64* E820 = E820_ENTRIES;

    mM->entries = MM_ENTRIES;

    //fill mM->entries
    u16 index = 0;
    for (u16 i = 0; i < *(u64*)E820_COUNT; ++i) {
        //remove length 0 entries
        if (*(E820 + 1) == 0) {
            E820 += 3;
            continue;
        }

        //remove entries with acpi ignore bit unset
        if ((*((u32*)(E820 + 2) + 1) & 1) == 0) {
            E820 += 3;
            continue;
        }

        mM->entries[index].start = *E820;
        mM->entries[index].length = *(E820 + 1);
        mM->entries[index].type = *(u32*)(E820 + 2);
        mM->entries[index].acpi = *((u32*)(E820 + 2) + 1);

        //if the memory is non volotile, set the type to bad
        //TODO figure out if the memory is usable
        if ((mM->entries[index].acpi & 2) == 2) {
            mM->entries[index].type = BAD;
        }

        E820 += 3;
        ++index;
    }

    mM->size = index;

    //bubble sort entries
    MemoryMapEntry temp;
    for (u16 i = 0; i < mM->size; ++i) {
        for (u16 j = 0; j < mM->size; ++j) {
            if (mM->entries[i].start < mM->entries[j].start) {
                temp = mM->entries[j];
                mM->entries[j] = mM->entries[i];
                mM->entries[i] = temp;
            }
        }
    }

    for (i16 i = mM->size - 2; i >= 0; --i) {
        //check for overlaps
        if (mM->entries[i].start + mM->entries[i].length > mM->entries[i + 1].start) {
            return true;
        }

        //combine adjecent memories of the same type and acpi
        if ((mM->entries[i].start + mM->entries[i].length == mM->entries[i + 1].start) && (mM->entries[i].type == mM->entries[i + 1].type) && (mM->entries[i].acpi == mM->entries[i + 1].acpi)) {
            mM->entries[i].length += mM->entries[i + 1].length;
            --mM->size;
            for (u16 j = i + 1; j < mM->size; ++j) {
                mM->entries[j].start = mM->entries[j + 1].start;
                mM->entries[j].length = mM->entries[j + 1].length;
                mM->entries[j].type = mM->entries[j + 1].type;
                mM->entries[j].acpi = mM->entries[j + 1].acpi;
            }
        }

        //remove free memory under 0x100000
        if ((mM->entries[i].start <= 0x100000) && (mM->entries[i].type == FREE)) {
            if (mM->entries[i].start + mM->entries[i].length <= 0x100000) {
                --mM->size;
                for (u16 j = i; j < mM->size; ++j) {
                    mM->entries[j].start = mM->entries[j + 1].start;
                    mM->entries[j].length = mM->entries[j + 1].length;
                    mM->entries[j].type = mM->entries[j + 1].type;
                    mM->entries[j].acpi = mM->entries[j + 1].acpi;
                }
            } else {
                mM->entries[i].length += mM->entries[i].start - 0x100000;
                mM->entries[i].start = 0x100000;
            }
        }
    }

    //TODO
    //align with page tables
    //reclaim acpi reclamable

    return false;
}

/**
 * @brief prints the memory map
 */
void print_memory_map(void) {
    i8 str0[] = "Memory Map:\nSize: ";
    i8 str1[] = "\nStart             |Length            |Type      |Acpi      \n";
    i8 str2[] = "|";
    i8 str3[] = "\n";

    MemoryMap* mM = MM_BASE;

    print_string(str0);
    print_hex((void*)&(mM->size), 16);
    print_string(str1);

    for (u16 i = 0; i < mM->size; ++i) {
        print_hex((void*)&(mM->entries[i].start), 64);
        print_string(str2);
        print_hex((void*)&(mM->entries[i].length), 64);
        print_string(str2);
        print_hex((void*)&(mM->entries[i].type), 32);
        print_string(str2);
        print_hex((void*)&(mM->entries[i].acpi), 32);
        print_string(str3);
    }
}
