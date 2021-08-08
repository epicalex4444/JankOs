/**
 * @file malloc.c
 * @brief physical memory allocator
 */

#include "malloc.h"
#include "print.h"

/// sets up bit map for malloc and free functions
void init_malloc() {
    MemoryMap* mM = MM_BASE;

    BitMap* bitMap = BITMAP_BASE;
    bitMap->entries = BITMAP_ENTRIES;
    bitMap->size = 0;

    for (u16 i = 0; i < mM->size; ++i) {
        if (mM->entries[i].type == FREE) {
            bitMap->entries[bitMap->size].start = mM->entries[i].start;
            bitMap->entries[bitMap->size].length = mM->entries[i].length;
            bitMap->entries[bitMap->size].type = FREE;
            ++bitMap->size;
        }
    }
}

/**
 * @brief allocates size bytes for and returns the pointer
 * @param ptr used to return the pointer
 * @param bytes the bytes to be allocated
 * @return pointer to allocated memory, null on error
 * @details Uses a very basic "waterfall" algorithm.
 *          Adjacent reserved slices are not combined.
 */
void* malloc(u64 bytes) {
    BitMap* bitMap = BITMAP_BASE;
    u64 bits = bytes * 8;

    //terrible amount of space need to figure out fixed memory space better
    if (bitMap->size >= 58) {
        return 0;
    }

    for (u64 i = 0; i < bitMap->size; ++i) {
        if ((bitMap->entries[i].type == FREE) && (bitMap->entries[i].length >= bits)) {
            if (bitMap->entries[i].length == bits) {
                bitMap->entries[i].type = RESERVED;
            } else {
                ++bitMap->size;

                for (u64 j = bitMap->size; j > i; --j) {
                    bitMap->entries[j] = bitMap->entries[j - 1];
                }

                bitMap->entries[i].start = bitMap->entries[i + 1].start;
                bitMap->entries[i].length = bits;
                bitMap->entries[i].type = RESERVED;

                bitMap->entries[i + 1].start += bitMap->entries[i].length;
                bitMap->entries[i + 1].length -= bitMap->entries[i].length;
            }

            return (void*)bitMap->entries[i].start;
        }
    }

    return 0;
}

/**
 * @brief frees memory from ptr of size bytes
 * @param ptr start address
 * @param size bytes to free
 * @return set on error
 * @details This function can be passed invalid ptr that weren't
 *          malloced so because of this it returns an error.
 *          combines adjacent free slices. The ptr and size must
 *          match a reserved slice else it is invalid.
 */
bool free(void* ptr, u64 bytes) {
    BitMap* bitMap = BITMAP_BASE;
    u64 bits = bytes * 8;

    for (u64 i = 0; i < bitMap->size; ++i) {
        if (bitMap->entries[i].start == (u64)ptr) {
            if ((bitMap->entries[i].length != bits) || (bitMap->entries[i].type != RESERVED)) {
                return true;
            }

            bitMap->entries[i].type = FREE;

            //try to combine behind
            if ((bitMap->entries[i - 1].type == FREE) && (i != 0) && (bitMap->entries[i - 1].start + bitMap->entries[i - 1].length == bitMap->entries[i].start)) {
                bitMap->entries[i - 1].length += bitMap->entries[i].length;
                --bitMap->size;
                for (u64 j = i; j < bitMap->size; ++j) {
                    bitMap->entries[j] = bitMap->entries[j + 1];
                }
                --i; //the index was moved back 1 so we have to point i to it
            }
            
            //try to combine infront
            if ((bitMap->entries[i + 1].type == FREE) && (i != bitMap->size) && (bitMap->entries[i].start + bitMap->entries[i].length == bitMap->entries[i + 1].start)) {
                bitMap->entries[i].length += bitMap->entries[i + 1].length;
                --bitMap->size;
                for (u64 j = i + 1; j < bitMap->size; ++j) {
                    bitMap->entries[j] = bitMap->entries[j + 1];
                }
            }

            return false;
        }
    }

    return true;
}

/// prints the bitmap
void print_bitmap() {
    i8 str0[] = "BitMap:\nSize: ";
    i8 str1[] = "\nStart             |Length            |Type\n";
    i8 str2[] = "|";
    i8 str3[] = "\n";

    BitMap* bitMap = BITMAP_BASE;

    print_string(str0);
    print_hex((void*)&(bitMap->size), 64);
    print_string(str1);

    for (u64 i = 0; i < bitMap->size; ++i) {
        print_hex((void*)&(bitMap->entries[i].start), 64);
        print_string(str2);
        print_hex((void*)&(bitMap->entries[i].length), 64);
        print_string(str2);
        print_hex((void*)&(bitMap->entries[i].type), 8);
        print_string(str3);
    }
}
