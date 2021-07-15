/**
 * @file string.c
 * @brief string function definitions
 */

#include "string.h"

/**
 * @brief finds the length of a string
 * @param str string
 * @return length
 * @details currently unused but probably going to use again,
 *          used to be used in print_string
 */
u16 str_len(i8* str) {
    u16 len = 0;
    while (*str != 0) {
        ++str;
        ++len;
    }
    return len;
}
