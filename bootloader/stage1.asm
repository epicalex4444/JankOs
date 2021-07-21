[org 0x7C00]
[bits 16]

;set cs to 0
jmp 0x0000:clearCs
clearCs:

;set all the segment registers to 0
xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

;move stack to below the boot sector
mov sp, 0x7C00
mov bp, 0x7C00

;save bootdisk in memory
mov BYTE [BOOT_DISK], dl

;enable the A20 line - doesn't work on older systems
in al, 0x92
or al, 0x02
out 0x92, al

;loads rest of the bootloader and the kernel
;capped at 255 sectors
mov dl, [BOOT_DISK]     ;disk
mov dh, 0xFF            ;sector count
xor ch, ch              ;cylinder
mov cl, 2               ;sector, starts at 1
mov bx, 0x7E00          ;base address
loadLoop:               ;
    cmp dh, 1           ;error if sectors = 1
    je die              ;
    mov al, dh          ;move sectors into al
    push dx             ;save sector count
    xor dh, dh          ;head
    mov ah, 2           ;interupt code
    int 0x13            ;call bios interupt
    pop dx              ;return sector count
    dec dh              ;decrement sector count
    jc loadLoop         ;check no error was returned
    dec al              ;decrement al so the comparison works
    cmp al, dh          ;check sectors read = sectors requested
    jne loadLoop        ;

;jump to next bootsector for space
jmp 0x7E00

die:
    hlt
    jmp die

BOOT_DISK: db 0x00

;pad 0's until partition table
times 446 - ($-$$) db 0

;partition table entries
times 64 db 0

;boot signature
dw 0xAA55
