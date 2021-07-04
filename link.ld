OUTPUT_FORMAT(binary)

SECTIONS {
    . = 0x7E00;
    .text : ALIGN(0x200) {
        *(.text)
    }
    .data : ALIGN(0x200) {
        *(.data)
    }
    .rodata : ALIGN(0x200) {
        *(.rodata)
    }
    .bss : ALIGN(0x200) {
        *(.bss)
    }
}
