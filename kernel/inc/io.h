/**
 * @file io.h
 * @brief inline function definition for io operations
 */

#pragma once

#include "types.h"
#include "attributes.h"

/**
 * @brief wrapper on outb assembly opcode
 * @param port represents an io port
 * @param val byte to send to the port
 */
INLINE void outb(u16 port, u8 val) {
    asm volatile ("out %1, %0" : : "a"(val), "Nd"(port));
}

/**
 * @brief wrapper on outw assembly opcode
 * @param port represents an io port
 * @param val word to send to the port
 */
INLINE void outw(u16 port, u16 val) {
    asm volatile ("out %1, %0" : : "a"(val), "Nd"(port));
}

/**
 * @brief wrapper on outl assembly opcode
 * @param port represents an io port
 * @param val dword to send to the port
 */
INLINE void outl(u16 port, u32 val) {
    asm volatile ("out %1, %0" : : "a"(val), "Nd"(port));
}

/**
 * @brief wrapper on inb assembly opcode
 * @param port represents an io port
 * @return byte from the port
 */
INLINE u8 inb(u16 port) {
    u8 ret;
    asm volatile ("in %0, %1" : "=a"(ret) : "Nd"(port));
    return ret;
}

/**
 * @brief wrapper on inw assembly opcode
 * @param port represents an io port
 * @return word from the port
 */
INLINE u16 inw(u16 port) {
    u16 ret;
    asm volatile ("in %0, %1" : "=a"(ret) : "Nd"(port));
    return ret;
}

/**
 * @brief wrapper on inl assembly opcode
 * @param port represents an io port
 * @return dword from the port
 */
INLINE u32 inl(u16 port) {
    u32 ret;
    asm volatile ("in %0, %1" : "=a"(ret) : "Nd"(port));
    return ret;
}
