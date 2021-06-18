;gdt layout -> https://wiki.osdev.org/GDT

;code segment bits
;base = 0x000000
;limit = 0xFFFFF
;preset = 1b
;privilege = 00b
;descriptor_type = 1b
;executable = 1b
;conforming = 0b
;readable/writeable = 1b
;accessed = 0b
;granularity = 1b
;32bit_default = 1b
;64bit_segment = 0 (reserved)
;AVL = 0           (reserved)

;data segment - same as code segment except
;executable = 0b

gdt_start:
    dd 0x00000000
    dd 0x00000000
gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:

;first 2 bytes is gdt size - 1
;next 4 bytes is the offset
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
