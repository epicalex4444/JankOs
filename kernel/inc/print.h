/**
 * @file print.h
 * @brief print function definitons
 */

#pragma once

#include "types.h"
#include "vga.h"

#define POS_MAX 1999 ///< last posible position to write to
#define NEXT_POS(pos) ((pos) == POS_MAX ? 0 : (pos) + 1) ///< gets the next position to write to
#define NEWLINE(pos) (pos / VGA_WIDTH * VGA_WIDTH + VGA_WIDTH) ///< returns start of next line position

void print_string(i8* str);

void print_hex(void* num, u8 size);
void print_hex_8(u8 num, u16 pos);
void print_hex_16(u16 num, u16 pos);
void print_hex_32(u32 num, u16 pos);
void print_hex_64(u64 num, u16 pos);

void print_binary(void* num, u8 size);
void print_binary_8(u8 num, u16 pos);
void print_binary_16(u16 num, u16 pos);
void print_binary_32(u32 num, u16 pos);
void print_binary_64(u64 num, u16 pos);
