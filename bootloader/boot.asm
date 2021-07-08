[org 0x7C00]
[bits 16]

;set cs to 0
;some BIOS' may load us at 0x0000:0x7C00 while other may load us at 0x07C0:0x0000
jmp 0x0000:flushCS
flushCS:

;set all the segment registers to 0
xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

;move stack to below the boot sector
mov sp, 0x7C00

;save bootdisk in memory
mov BYTE [BOOT_DISK], dl

;clear screen
mov ah, 0x06
xor al, al
xor bx, bx
mov bh, 0x0F
xor cx, cx
mov dh, 0x18
mov dl, 0x4F
int 0x10

;hide cursor
mov ah, 0x01
mov cx, 0x2607
int 0x10

;move cursor to the top left position
mov ah, 0x02
xor bx, bx
xor dx, dx
int 0x10

;enable the A20 line - doesn't work on older systems
in al, 92h
or al, 02h
out 92h, al

;load kernel into memory - capped at 255 sectors
mov dl, [BOOT_DISK]     ;disk
mov dh, 0xFF            ;max sectors
loadLoop:               ;
    mov al, dh          ;move sectors to read into al
    cmp al, 0           ;check sectors > 0
    je error.disk_read  ;
    call read_disk      ;try to load sectors into memory
    dec dh              ;decrement sector count
    jc loadLoop         ;check no error was returned
    dec al              ;decrement al so the comparison works
    cmp al, dh          ;check sectors read = sectors requested
    jne loadLoop        ;

;cpuid check
pushfd           ;
pop eax          ;copy flags register to eax
mov ecx, eax     ;copy to ecx to compare later
xor eax, 1 << 21 ;flip id bit
push eax         ;
popfd            ;copy eax to the flags register
pushfd           ;
pop eax          ;copy back flags to the eax register
xor eax, ecx     ;check if id bit was flipped, if not flipped cpuid is not supported
jz error.cpuid   ;
push ecx         ;
popfd            ;restore previous flags register

;extended functions check
mov eax, 0x80000000 ;
cpuid               ;
cmp eax, 0x80000001 ;
jb error.ext_funcs  ;

;long mode check
mov eax, 0x80000001 ;
cpuid               ;
test edx, 1 << 29   ;test if long mode bit is set
jz error.long_mode  ;

;generate memory map for the kernel to use
mov edx, 0x534D4150   ;smap code
mov di, 0x5000        ;base address for memory map
mov ebx, 0            ;continuation value, starts 0
memoryMapLoop:        ;
    mov eax, 0xE820   ;memory map bios function
    mov ecx, 24       ;buffer size
    int 0x15          ;call memory map interupt
    jc error.mm       ;
    add di, 24        ;iterate di
    cmp ebx, 0        ;check if finished
    jne memoryMapLoop ;

;setup identity paging for the first 2 megabytes
;the present bit an read/write bit is set on all entires
mov edi, 0x1000            ;PML4 start address
mov cr3, edi               ;point cr3 to PML4
xor eax, eax               ;clear tables
mov ecx, 4096              ;
rep stosd                  ;
mov DWORD [0x1000], 0x2003 ;point PML4 to PDP
mov DWORD [0x2000], 0x3003 ;point PDP to PD
mov DWORD [0x3000], 0x4003 ;point PD to PT
mov edi, 0x4000            ;PT start address
mov ebx, 0x00000003        ;start value
mov ecx, 512               ;512 iterations
pagingLoop:                ;
    mov DWORD [edi], ebx   ;write entry
    add ebx, 0x1000        ;update ebx to point to next memory location
    add edi, 8             ;update edi to next PT entry
    loop pagingLoop        ;

;load gdt
lgdt [gdt.descriptor]

;set bits for long mode
mov eax, 10100000b  ;set PAE and PGE bits
mov cr4, eax        ;
mov ecx, 0xC0000080 ;
rdmsr               ;
or eax, 0x00000100  ;set LME bit
wrmsr               ;
mov ebx, cr0	    ;
or ebx, 0x80000001  ;set PE and PG bits
mov cr0, ebx        ;

;flush instruction cache
;so we don't execute 16 bit code in long mode
jmp gdt.code:longMode

;params: bx = address of null terminated string
;returns: none
print_16:
    pusha            ;
    mov ah, 0xE      ;display char function
    .loop:           ;
        mov al, [bx] ;load char into al
        test al, al  ;test if al is 0
        jz .exit     ;if 0 exit
        int 0x10     ;call bios display char interupt
        inc bx       ;point to next char
        jmp .loop    ;
    .exit:           ;
        popa         ;
        ret          ;

;params:
;   dl = disk
;   al = sectors
;returns:
;   carry flag set on error
;   ah = status
;   al = sectors_read
read_disk:
    push bx             ;
    push cx             ;
    push dx             ;
    mov ah, 2           ;interupt code
    mov dh, 0           ;head
    mov ch, 0           ;cylinder
    mov cl, 2           ;sector, starts at 1
    mov bx, 0x7E00      ;base address
    int 0x13            ;call bios interupt
    pop dx              ;
    pop cx              ;
    pop bx              ;
    ret                 ;

;error handling, prints error messages then hangs
error:
    .disk_read:
        mov bx, DISK_READ_ERROR
        jmp .end
    .cpuid:
        mov bx, CPUID_ERROR
        jmp .end
    .ext_funcs:
        mov bx, EXT_FUNCS_ERROR
        jmp .end
    .long_mode:
        mov bx, LONG_MODE_ERROR
        jmp .end
    .mm:
        mov bx, MM_ERROR
    .end:
        call print_16
        jmp $

;strings
DISK_READ_ERROR: db 'Disk Read Error', 0
CPUID_ERROR:     db 'CPUID Not Supported', 0
EXT_FUNCS_ERROR: db 'Extended Functions Not Supported', 0
LONG_MODE_ERROR: db 'Long Mode Not Supported', 0
MM_ERROR:        db 'Memory Map Error', 0

BOOT_DISK: db 0x00

times 510 - ($ - $$) db 0 ;pad boot sector
dw 0xAA55 ;add boot signature

gdt:
.null equ $ - gdt  ;
    dq 0           ;mandatory null segment
.code equ $ - gdt  ;
    dw 0xFFFF      ;limit 0-15
    dw 0x0000      ;base 0-15
    db 0x00        ;base 16-23
    db 10011010b   ;present, privelege 2 bits, type, code, conforming, readable, accesed
    db 10101111b   ;granularity, 16/32, 64, avl, limit 16-19
    db 0x00        ;base 24-31
.data equ $ - gdt  ;
    dw 0xFFFF      ;limit 0-15
    dw 0x0000      ;base 0-15
    db 0x00        ;base 16-23
    db 10010010b   ;present, privelege 2 bits, type, code, conforming, readable, accesed
    db 10101111b   ;granularity, 16/32, 64, avl, limit 16-19
    db 0x00        ;base 24-31
.descriptor:       ;
    dw $ - gdt - 1 ;size
    dq gdt         ;base address

[bits 64]
longMode:

;update segment registers
mov ax, gdt.data
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

;disable interupts
cli

;jump to kernel (jumps to kernel_entry.asm)
jmp 0x8000

;additional sector
times 1024 - ($ - $$) db 0
