[bits 64]

;declare _start point
global _start
_start:

;sets up stack, at the top of available space
;above is bios a bios area, below is the kernel
;stack grows downwards
mov esp, 0x9FC00
mov ebp, 0x9FC00

;jumps to _start function in main.c
[extern start_kernel]
jmp start_kernel
