/**
 * @file print.h
 * @brief print function definitons
 */

#pragma once

#include "types.h"

#define POS_MAX 1999

void print_string(i8* str);
void print_hex(void* num, u8 size);
void print_hex_8(u8 num, u16 pos);
void print_hex_16(u16 num, u16 pos);
void print_hex_32(u32 num, u16 pos);
void print_hex_64(u64 num, u16 pos);
