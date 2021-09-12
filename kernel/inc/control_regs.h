/**
 * @file control_regs.h
 * @brief inline assembly functions for accessing control registers(also msr and cpuid)
 * @details shamelessly stolen from os dev wiki because inline assembly and gas are aweful
 */

#include "types.h"
#include "attributes.h"

INLINE u64 read_cr0(void) {
    u64 val;
    asm volatile ("mov cr0, %0" : "=r"(val));
    return val;
}

INLINE u64 read_cr2(void) {
    u64 val;
    asm volatile ("mov cr2, %0" : "=r"(val));
    return val;
}

INLINE u64 read_cr3(void) {
    u64 val;
    asm volatile ("mov cr3, %0" : "=r"(val));
    return val;
}

INLINE u64 read_cr4(void) {
    u64 val;
    asm volatile ("mov cr4, %0" : "=r"(val));
    return val;
}

INLINE void write_cr0(u64 val) {
    asm volatile ("mov cr0, %0" : "r"(val));
}

INLINE void write_cr3(u64 val) {
    asm volatile ("mov cr3, %0" : "r"(val));
}

INLINE void write_cr4(u64 val) {
    asm volatile ("mov cr4, %0" : "r"(val));
}

INLINE u64 rdmsr(u64 msr) {
    u64 val;
    asm volatile ("rdmsr" : "=A" (val) : "c" (msr));
    return val;
}

INLINE void wrmsr(u64 msr, u64 val) {
    u32 low = val;
	u32 high = val >> 32;
	asm volatile ("wrmsr" : : "c"(msr), "a"(low), "d"(high));
}

INLINE void cpuid(int code, u32* a, u32* d) {
    asm volatile ( "cpuid" : "=a"(*a), "=d"(*d) : "0"(code) : "ebx", "ecx" );
}
