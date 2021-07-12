/**
 * @file string.h
 * @brief string function declarations
 */

#pragma once

#include "types.h"

#define NUM_TO_HEX(num) ((num) < 10 ? (num) + 48 : (num) + 55) ///< converts a number from 0-15 into ascii for hex

u16 str_len(i8* str);
