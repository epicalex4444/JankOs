/**
 * @file io.c
 * @brief source file for low level io operations
 */

#include "io.h"

/**
 * @brief wrapper on outb assembly opcode
 * @param port represents an io port
 * @param val byte to send to the port
 */
void outb(u16 port, u8 val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

/**
 * @brief wrapper on outw assembly opcode
 * @param port represents an io port
 * @param val word to send to the port
 */
void outw(u16 port, u16 val) {
    asm volatile ("outw %0, %1" : : "a"(val), "Nd"(port));
}

/**
 * @brief wrapper on outl assembly opcode
 * @param port represents an io port
 * @param val dword to send to the port
 */
void outl(u16 port, u32 val) {
    asm volatile ("outl %0, %1" : : "a"(val), "Nd"(port));
}

/**
 * @brief wrapper on inb assembly opcode
 * @param port represents an io port
 * @return byte from the port
 */
u8 inb(u16 port) {
    u8 ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

/**
 * @brief wrapper on inw assembly opcode
 * @param port represents an io port
 * @return word from the port
 */
u16 inw(u16 port) {
    u16 ret;
    asm volatile ("inw %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

/**
 * @brief wrapper on inl assembly opcode
 * @param port represents an io port
 * @return dword from the port
 */
u32 inl(u16 port) {
    u32 ret;
    asm volatile ("inl %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}
