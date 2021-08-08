;starting environment
;loaded to 0x0000:0x7C00 by the mbr
;dl = boot drive
;si = partition entry
;segment registers = 0
;stack pointer = 0x7C00
;bios interupts enabled
;real mode

;what this vbr does
;read fs to find kernel
;load kernel into memory
;get into long mode
;   identity paging
;   bare minimum gdt
;   disble bios interupts
;   update segment registers
;hand over to the kernel
;maintains bootdrive and partition entry

[org 0x7C00]
[bits 16]

VBR_SECTORS: equ 2
VBR_END: equ 0x8000

;save partition entry and boot drive
mov [partitionEntry], si
mov [bootDrive], dl

;load the rest of the vbr
mov ah, 0x42
mov si, dap
int 0x13
jc error.kernel

;move root folder lba into dap
mov WORD [dap.offset], VBR_END ;set offset to after the vbr
mov si, [partitionEntry]       ;mov back partition entry address
add si, 8                      ;point to lba lower
mov ebx, [si]                  ;mov lba lower into eax
add ebx, VBR_SECTORS           ;point to the root folder and not the vbr
mov [dap.lba_lower], ebx       ;

;load 1st sector of root folder
mov ah, 0x42
mov si, dap
int 0x13
jc error.kernel

;move sectors from root folder to dap
mov si, VBR_END
mov di, dap.sectors
movsw

;load whole root folder
mov ah, 0x42
mov si, dap
int 0x13
jc error.kernel

;check fileNum >= 1
mov al, BYTE [VBR_END + 8]
cmp al, 1
jl error.kernel

;setup dap for loading file headers
mov WORD [dap.sectors], 1 ;change dap sectors to 1
mov bx, [dap.offset]      ;get current offset
mov ax, [VBR_END]         ;get root folder sectors
mov dx, 512               ;calculate offset after root folder
mul dx                    ;
add bx, ax                ;
mov [dap.offset], bx      ;set dap offset

;search for kernel.bin file
mov ecx, [VBR_END + 8]       ;loop iterations = fileNum
mov bx, VBR_END + 0x1A       ;address of first file lba
fileLoop:                    ;
    mov edx, [bx]            ;get lba offset from root folder
    mov [dap.lba_lower], edx ;set lba in dap
    mov ah, 0x42             ;bios code for extended read
    mov dl, [bootDrive]      ;set boot drive
    mov si, dap              ;set dap address
    int 0x13                 ;call extended read
    jc error.kernel          ;error
    mov ax, KERNEL_BIN       ;load kernel.bin string
    mov dx, [dap.offset]     ;get address of fileName
    add dx, 0x08             ;
    call strCmp              ;check if fileName is kernel.bin
    je fileLoopEnd           ;if kernel.bin the kernel is found and we can exit
    loop fileLoop            ;loop
    jmp error.kernel         ;kernel couldn't be located error
fileLoopEnd:                 ;

;setup dap for loading the kernel
mov ax, [bx]                  ;address of lba of kernel.bin header(in root folder header)
inc ax                        ;point to next sector which is kernel.bin
mov [dap.lba_lower], ax       ;set lba
mov bx, [dap.offset]          ;address of kernel.bin length(in file header)
mov dx, [bx]                  ;length of kernel.bin in sectors
mov [dap.sectors], dx         ;dap sectors address
mov WORD [dap.offset], 0x8000 ;set kernel memory offset

;store kernel length for later
mov [kernelSectors], dx

;load kernel
mov ah, 0x42
mov dl, [bootDrive]
mov si, dap
int 0x13
jc error.kernel

;cpuid check
pushfd             ;
pop eax            ;copy flags register to eax
mov ecx, eax       ;copy to ecx to compare later
xor eax, 1 << 21   ;flip id bit
push eax           ;
popfd              ;copy eax to the flags register
pushfd             ;
pop eax            ;copy back flags to the eax register
xor eax, ecx       ;check if id bit was flipped, if not flipped cpuid is not supported
je error.long_mode ;
push ecx           ;
popfd              ;restore previous flags register

;extended functions check
mov eax, 0x80000000 ;get highest ext function
cpuid               ;
cmp eax, 0x80000001 ;check if 0x80000001 is available
jb error.long_mode  ;

;long mode check
mov eax, 0x80000001 ;get extended processor info
cpuid               ;
test edx, 1 << 29   ;test if long mode bit is set
je error.long_mode  ;

;jump to extended vbr space
jmp extendedVbr

;params: bx = address of null terminated string
;returns: none
print_string:
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
;   ax = address of null terminated string 1
;   dx = address of null terminated string 2
;returns: zf unset on match else set
strCmp:
    pusha              ;
    .loop:             ;
        mov bx, ax     ;load str1 char into cl
        mov cl, [bx]   ;
        mov bx, dx     ;load str2 char into ch
        mov ch, [bx]   ;
        cmp cl, ch     ;check whether the chars are equal
        jne .notEqual  ;exit not equal
        test cl, cl    ;test if str1/str2 has ended
        jz .equal      ;exit equal equal
        inc ax         ;point to next str1 char
        inc dx         ;point to next str2 char
        jmp .loop      ;loop
    .notEqual:         ;
        pushfd         ;set cx to flags register
        pop cx         ;
        and cx, 0xFFBF ;clear zero flag
        jmp .exit      ;
    .equal:            ;
        pushfd         ;set cx to flags register
        pop cx         ;
        or cx, 0x0040  ;set zero flag
    .exit:             ;
        push cx        ;set flags register to cx
        popfd          ;
        popa           ;
        ret            ;

;error handling, prints error messages then hangs
error:
    .kernel:
        mov bx, KERNEL_ERROR
        jmp .end
    .long_mode:
        mov bx, LONG_MODE_ERROR
        jmp .end
    .mm:
        mov bx, MM_ERROR
    .end:
        call print_string
    .die:
        hlt
        jmp .die

;strings
KERNEL_BIN:      db "kernel.bin", 0
KERNEL_ERROR:    db "failed to locate the kernel", 0
LONG_MODE_ERROR: db "long mode not supported", 0
MM_ERROR:        db "memory map error", 0

;disk address packet
;default is setup for loading the rest of the vbr
dap:
.size:      db 0x10
.null:      db 0
.sectors:   dw 1      ;placeholder
.offset:    dw 0x7E00 ;placeholder
.segment:   dw 0
.lba_lower: dd 2      ;placeholder
.lba_upper: dd 0      ;placeholder

partitionEntry: dw 0
bootDrive: db 0
kernelSectors: dd 0

;pad sector
times 510 - ($ - $$) db 0

;boot signature
dw 0xAA55

;extended vbr area
extendedVbr:

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

;generate memory map for the kernel to use
mov edx, 0x534D4150           ;smap code
xor ax, ax                    ;set count to 0
mov [0x5000], ax              ;
mov di, 0x5002                ;base address for memory map
xor ebx, ebx                  ;continuation value, starts at 0
memoryMapLoop:                ;
    mov eax, 0xE820           ;memory map bios function
    mov ecx, 24               ;buffer size
    mov [es:di + 20], dword 1 ;force valid acpi 3.x submission
    int 0x15                  ;call memory map interupt
    jc error.mm               ;
    add di, 24                ;iterate di
    mov ax, [0x5000]          ;interate count
    inc ax                    ;
    mov [0x5000], ax          ;
    test ebx, ebx             ;check if finished
    jne memoryMapLoop         ;

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
;so we don't execute real mode code in long mode
jmp gdt.code:longMode

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

;disable interupts
cli

;update segment registers
mov ax, gdt.data
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

;move kernel
cld                      ;clear direction flag
mov rcx, [kernelSectors] ;load sectors into rcx
shl rcx, 6               ;multiply by 64(each sector is 64 quad words)
mov rsi, 0x8000          ;source address
mov rdi, 0x100000        ;destination address
rep movsq                ;repeat moving 64bits from source to destination

;set bootdrive and partition entry
mov si, [partitionEntry]
mov dl, [bootDrive]

;jump to kernel (jumps to kernel_entry.asm)
jmp 0x100000

;sector align extra space
times 1024 - ($ - $$) db 0
