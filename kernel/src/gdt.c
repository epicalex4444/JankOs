/**
 * @file gdt.h
 * @brief function definitions for the gdt
 */

#include "gdt.h"

void init_gdt() {
    GDT gdt = {
        .null = {0, 0, 0, 0, 0, 0},
        .code = {0, 0, 0, 0x9A, 0xA0, 0},
        .data = {0, 0, 0, 0x92, 0xA0, 0}
    };

    GDTDescriptor gdtDescriptor = {
        sizeof(gdt) * 8 - 1,
        (u64)&gdt
    };

    load_gdt(&gdtDescriptor);
}

NAKED void load_gdt(GDTDescriptor* gdtDescriptor) {
    asm volatile (
        "lgdt [%0]\n"
        "mov ax, 0x10\n"
        "mov ds, ax\n"
        "mov es, ax\n"
        "mov fs, ax\n"
        "mov gs, ax\n"
        "mov ss, ax\n"
        "pop rdi\n"
        "mov rax, 0x08\n"
        "push rax\n"
        "push rdi\n"
        "retfq\n"
        :
        : "r" (gdtDescriptor)
        : "rax"
    );
}
