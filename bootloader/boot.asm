;The bios has just loaded us into memory and starting executing our code.
;Currently we are in 16bit real mode, the A20 line is disabled and the disk is
;uninitialised. Our job is to get the cpu to long mode, enable the A20 line,
;initialise the kernel and then hand over to the kernel.
;I also am going to initialise the kernel with the memory map,
;because it should be done with the bios.

;This bootlooder is not going to load the kernel if the those tasks 
;can't be completed and will instead log an error and hang.
;This bootloader is also going to do the bare minimum to achieve those tasks
;and is going to rely upon the kernel to optimise things once it is loaded.

[bits 16]

;move stack out of the way
mov bp, 0x7C00
mov sp, bp

;enable the A20 line - this doesn't always work
in al, 0x92
or al, 0x02
out 0x92, al

;read sectors 1-5 - sectors are 512 bytes
;bios automatically loads boot drive into dl
mov al, 0x01
call read_disk

;need to add memory map here since it uses bios interupts

;bios interupts shouldn't be used form here onwards
cli

;load the gdt
lgdt [gdt_descriptor]

;enable protected mode bit in the cr0 register
mov eax, cr0
or eax, 0x1
mov cr0, eax

;far jump to avoid pipelining issues
jmp CODE_SEG:protected_mode

%include "print_16.asm" ;relies on vga, which is not always supported
%include "read_disk.asm"
%include "gdt.asm"

[bits 32]

protected_mode:

;disable bios interupts - they are only meant for real mode
cli

;update stack registers - protected mode changes how segmenting works
mov ax, DATA_SEG
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax

call detect_long_mode
call setup_paging

;update gdt to use 64 bit mode - clear 16/32 0 and set 64 bit pin
mov [CODE_SEG + 6], BYTE 0xAF
mov [DATA_SEG + 6], BYTE 0xAF

;enable long mode
mov ecx, 0xC0000080 ;set ecx to the efer msr
rdmsr               ;read the model specific register
or eax, 1 << 8      ;set the long mode bit
wrmsr               ;write the long mode bit to the efer msr

;far jump to avoid pipelining issues
jmp CODE_SEG:long_mode

%include "print_32.asm" ;relies on vga, which is not always supported

;pad boot sector with 0's and add boot signature
times 510 - ($ - $$) db 0x00
dw 0xAA55

;extra stuff down here because not everything fit into 512 bytes
;this stuff has to be read first before getting used

%include "detect_long_mode.asm"
%include "paging.asm"

[bits 64]

long_mode:

;hang
jmp $

times 1024 - ($ - $$) db 0x00
