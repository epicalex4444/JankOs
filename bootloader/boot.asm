;The bios has just loaded us into memory and starting executing our code.
;Currently we are in 16bit real mode, the A20 line is disabled and the disk is
;uninitialised. Our job is to get the cpu to long mode, enable the A20 line,
;initialise the kernel and then hand over to the kernel.
;I also am going to initialise the kernel with the memory map,
;because it should be done with the bios

;This bootlooder is not going to load the kernel if the those tasks 
;can't be completed and will instead log an error and hang.
;This bootloader is also going to do the bare minimum to achieve those tasks
;and is going to rely upon the kernel to optimise things once it is loaded.

[org 0x7C00]
[bits 16]

;move stack out of the way
mov bp, 0x7C00
mov sp, bp

;bios automatically loads boot drive into dl
mov al, 0x04
call read_disk

;need add memory map here since it uses bios interupts

;bios interupts shouldn't be used form here onwards
cli

;enable the A20 line
in al, 0x92
or al, 0x02
out 0x92, al

;load the gdt
lgdt [gdt_descriptor]

;enable protected mode bit in the cr0 register
mov eax, cr0
or eax, 0x1
mov cr0, eax

;far jump avoid pipelining issues
jmp CODE_SEG:pm

%include "print_16.asm" ;relies on vga, which is not always supported
%include "read_disk.asm"
%include "gdt.asm"

[bits 32]

pm:

;disable bios interupts because they can't be used in protected mode
cli

;update stack registers
mov ax, DATA_SEG
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax

;hang
jmp $

%include "print_32.asm" ;relies on vga, which is not always supported

;make file 512 bytes and add boot signature(both needed to run)
times 510 - ($ - $$) db 0x00
dw 0xAA55
