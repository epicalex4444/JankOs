/**
 * @file string.c
 * @brief string function definitions
 */

#include "string.h"

u16 str_len(i8* str) {
    u16 len = 0;
    while (*str != 0) {
        ++str;
        ++len;
    }
    return len;
}