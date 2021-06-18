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

mov bp, 0x7C00
mov sp, bp ;move stak out of the way

;bios automatically loads boot drive into dl
mov al, 0x04
call read_disk

jmp $

%include "print.asm" ;relies on vga, which is not always supported
%include "read_disk.asm"

;make file 512 bytes and add boot signature(both needed to run)
times 510 - ($ - $$) db 0x00
dw 0xAA55
