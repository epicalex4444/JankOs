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

;because of little endianes db, dw and dd are backwards

gdt_start:
    dd 0x00000000
    dd 0x00000000
gdt_code:
    dd 0x0000FFFF
    dd 0x00CF9A00
gdt_data:
    dd 0x0000FFFF
    dd 0x00CF9200
gdt_end:

;first 2 bytes is gdt size - 1
;next 4 bytes is the offset
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dq gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
