;starting environment
;loaded to 0x0000:0x7C00 by the mbr
;dl = boot drive
;si = partition entry
;segment registers = 0
;stack pointer = 0x7C00
;base pointer = 0x7C00
;bios interupts enabled
;real mode

;what this vbr does
;read fs to find kernel.bin
;generate memory map
;load kernel.bin to temporary spot
;get into long mode
;   identity paging
;   bare minimum gdt
;move kernel.bin to 0x100000
;update mM to make sure the kernel is in reserved memory
;update segment registers
;disble bios interupts
;dl and si are set back to starting values
;hand over to the kernel

;declare current state to the assembler
[org 0x7C00]
[bits 16]

;macros
VBR_SECTORS: equ 3

FILE_HEADER_OFFSET: equ 0x7C00 + VBR_SECTORS * 0x200
FILE_HEADER_SECTORS: equ FILE_HEADER_OFFSET
FILE_HEADER_FILE_NAME: equ FILE_HEADER_OFFSET + 8

FOLDER_HEADER_OFFSET: equ FILE_HEADER_OFFSET + 0x200
FOLDER_HEADER_SECTORS: equ FOLDER_HEADER_OFFSET
FOLDER_HEADER_FILE_NUM: equ FOLDER_HEADER_OFFSET + 4
FOLDER_HEADER_FILE_LBA: equ FOLDER_HEADER_OFFSET + 14

MM_OFFSET: equ 0x5000
MM_SIZE: equ MM_OFFSET
MM_ENTRIES: equ MM_OFFSET + 2

PAGE_TABLES_OFFSET: equ 0x1000
PML4: equ PAGE_TABLES_OFFSET
PDP: equ PML4 + 0x1000
PD: equ PDP + 0x1000
PT: equ PD + 0x1000

TEMP_KERNEL_OFFSET: equ FILE_HEADER_OFFSET
KERNEL_OFFSET: equ 0x100000

;save partition entry and boot drive in memory
mov [partitionEntry], si
mov [bootDrive], dl

;load the rest of the vbr
mov ah, 0x42
mov si, dap
int 0x13
jc error.kernel

;move root folder lba into dap
mov WORD [dap.offset], FOLDER_HEADER_OFFSET ;set dap offset to the folder header
mov si, [partitionEntry]                    ;load partition entry address into si
add si, 8                                   ;point to the lba in the partition entry
mov ebx, [si]                               ;mov lba into ebx
add ebx, VBR_SECTORS                        ;add vbr offset to point to the root folder
jno noOverflow                              ;check for overflow
mov DWORD [dap.lba_upper], 1                ;if oveflow we set upper lba in dap to 1(it is always 0 before)
noOverflow:                                 ;
mov [dap.lba_lower], ebx                    ;set lower in dap

;load 1st sector of root folder
mov ah, 0x42
mov si, dap
int 0x13
jc error.kernel

;move sectors from root folder to dap
mov si, FOLDER_HEADER_SECTORS
mov di, dap.sectors
movsw

;load whole root folder
mov ah, 0x42
mov si, dap
int 0x13
jc error.kernel

;check fileNum >= 1
mov eax, [FOLDER_HEADER_FILE_NUM]
cmp eax, 1
jl error.kernel

;setup dap for loading file headers
mov WORD [dap.sectors], 1
mov WORD [dap.offset], FILE_HEADER_OFFSET

;search for kernel.bin file
;stores lba of kernel.bin in bx
mov ecx, [FOLDER_HEADER_FILE_NUM] ;loop iterations = fileNum
mov bx, FOLDER_HEADER_FILE_LBA    ;address of first file lba
fileLoop:                         ;
    mov edx, [bx]                 ;set lba_lower in dap
    mov [dap.lba_lower], edx      ;
    add bx, 4                     ;point to upper lba
    mov edx, [bx]                 ;set lba_upper in dap
    mov [dap.lba_upper], edx      ;
    mov ah, 0x42                  ;bios code for extended read
    mov dl, [bootDrive]           ;set boot drive
    mov si, dap                   ;set dap address
    int 0x13                      ;call extended read
    jc error.kernel               ;
    mov ax, KERNEL_BIN            ;load kernel.bin string
    mov dx, FILE_HEADER_FILE_NAME ;fileName address
    call strCmp                   ;check if fileName is kernel.bin
    je fileLoopEnd                ;if kernel.bin is found and we can exit
    add bx, 4                     ;point to next lba
    loop fileLoop                 ;
    jmp error.kernel              ;kernel couldn't be located error
fileLoopEnd:                      ;
sub bx, 4                         ;point to lba start, not upper half

;setup dap for loading the kernel
mov WORD [dap.offset], TEMP_KERNEL_OFFSET ;set kernel memory offset
mov eax, [bx]                             ;set eax to lba_lower
add bx, 4                                 ;point to lba_upper
mov ecx, [bx]                             ;set ecx to lba_upper
inc eax                                   ;point to next sector which is kernel.bin
jno noOverflow2                           ;check for overflow
inc ecx                                   ;add 1 to upper
jo error.kernel                           ;if this overflows it's an error
noOverflow2:                              ;
mov [dap.lba_lower], eax                  ;set lba in dap
mov [dap.lba_upper], ecx                  ;
mov edx, [FILE_HEADER_SECTORS]            ;load kernel.bin sectors into dx(uses edx to 0 the top half for later)
mov [dap.sectors], dx                     ;set dp sectors

;store kernel size for later(multiple by 512 to store in bytes)
shl edx, 9
mov [kernelBytes], edx

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
;returns: zf set on match else unset
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
        jz .equal      ;exit equal
        inc ax         ;point to next str1 char
        inc dx         ;point to next str2 char
        jmp .loop      ;
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
.sectors:   dw VBR_SECTORS - 1
.offset:    dw 0x7E00
.segment:   dw 0
.lba_lower: dd 2
.lba_upper: dd 0

partitionEntry: dw 0
bootDrive: db 0
kernelBytes: dd 0

;pad sector
times 510 - ($ - $$) db 0

;boot signature
dw 0xAA55

;extended vbr area
extendedVbr:

;setup identity paging for the first 2 megabytes
;the present bit an read/write bit is set on all entires
mov edi, PML4             ;PML4 start address
mov cr3, edi              ;point cr3 to PML4
xor eax, eax              ;clear tables
mov ecx, 4096             ;
rep stosd                 ;
mov DWORD [PML4], PDP + 3 ;point PML4 to PDP
mov DWORD [PDP], PD + 3   ;point PDP to PD
mov DWORD [PD], PT + 3    ;point PD to PT
mov edi, PT               ;PT start address
mov ebx, 0x00000003       ;start value
mov ecx, 512              ;512 iterations
pagingLoop:               ;
    mov DWORD [edi], ebx  ;write entry
    add ebx, 0x1000       ;update ebx to point to next memory location
    add edi, 8            ;update edi to next PT entry
    loop pagingLoop       ;

;generate E820 memory map
mov edx, 0x534D4150           ;smap code
xor ax, ax                    ;set count to 0
mov [MM_SIZE], ax             ;
mov di, MM_ENTRIES            ;base address for memory map
xor ebx, ebx                  ;continuation value, starts at 0
memoryMapLoop:                ;
    mov eax, 0xE820           ;memory map bios function
    mov ecx, 24               ;buffer size
    mov [es:di + 20], dword 1 ;force valid acpi 3.x submission
    int 0x15                  ;call memory map interupt
    jc error.mm               ;
    add di, 24                ;iterate di
    mov ax, [MM_SIZE]         ;iterate count
    inc ax                    ;
    mov [MM_SIZE], ax         ;
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

;check if kernel fits into memory map
;also finds the entry where the kernel fits into
xor rcx, rcx               ;0 rcx
mov cx, [MM_SIZE]          ;move mm.size into cx
mov rsi, MM_ENTRIES        ;mov mm.entries address into rsi
xor r8, r8                 ;0 r8
mov r8d, [kernelBytes]     ;mov kernel.sectors into r8
kernelLoop:                ;
    mov r9, [rsi]          ;move mm.offset into r9
    add rsi, 8             ;point to mm.length
    mov r10, [rsi]         ;move mm.length into r10
    add rsi, 8             ;point to mm.type
    mov r11, [rsi]         ;move mm.type into r11
    add rsi, 4             ;point to mm.acpi
    mov r12, [rsi]         ;move mm.acpi into r12
    add rsi, 4             ;point to next entry
    cmp r11d, 1            ;if mm.type != 1
    jne .invalid           ;
    test r12d, 1           ;if mm.acpi & 1
    je .invalid            ;
    cmp r9, KERNEL_OFFSET  ;if mm.offset > kernel.offset
    jg .invalid            ;
    add r8, KERNEL_OFFSET  ;if kernel.length + kerneloffset < mm.length
    cmp r10, r8            ;
    jl .invalid            ;
    jmp .valid             ;passed all checks kernel can fit in this entry
    .invalid:              ;
    loop kernelLoop        ;
    jmp error.die          ;didn't find a valid entry error
    .valid:                ;
    dec rcx                ;valid entry index
    sub rsi, 24            ;valid entry offset

;make kernel be in reserved memory
mov r8, KERNEL_OFFSET          ;move kernel.offset into r8
cmp r8, [rsi]                  ;if mm.offset == kernel.offset
je notSplitBelow               ;
call pushMMDown                ;split entry into 2 copies
inc rcx                        ;update index(pushMMDown uses the index)
sub r8, [rsi]                  ;mm.length = 0x100000 - mm.offset
add rsi, 8                     ;point to mm.length
mov [rsi], r8                  ;
add rsi, 16                    ;point to next entry
mov QWORD [rsi], KERNEL_OFFSET ;set mm.offset to kernel.offset
add rsi, 8                     ;point to mm.length
mov r9, [rsi]                  ;r9 = entry2.length
sub r9, r8                     ;entry2.length -= entry1.length
mov [rsi], r9                  ;
sub rsi, 8                     ;point to start of entry
notSplitBelow:                 ;
xor r8, r8                     ;
mov r8d, [kernelBytes]         ;move kernel.length into r8
add rsi, 8                     ;point to mm.length
cmp r8, [rsi]                  ;if mm.length == kernel.length
je notSplitAbove               ;
call pushMMDown                ;split entry into 2 copies
mov [rsi], r8                  ;mm.length = kernel.length
add rsi, 16                    ;point to next entry
mov r9, [rsi]                  ;move mm.offset into r9
add r9, r8                     ;mm.offset += kernel.length
mov [rsi], r9                  ;
add rsi, 8                     ;point to mm.length
mov r9, [rsi]                  ;move mm.length into r9
sub r9, r8                     ;mm.length -= kernel.length
mov [rsi], r9                  ;
sub rsi, 32                    ;point to start of entry
notSplitAbove:                 ;
add rsi, 16                    ;point to mm.type
mov DWORD [rsi], 2             ;set to reserved

;move kernel
xor rcx, rcx
mov ecx, [kernelBytes]    ;load sectors into rcx
mov rsi, TEMP_KERNEL_OFFSET ;source address
mov rdi, KERNEL_OFFSET      ;destination address
call movMemOverlap

;restore dl and si for use by the kernel
mov si, [partitionEntry]
mov dl, [bootDrive]

;jump to kernel (jumps to kernel_entry.asm)
jmp KERNEL_OFFSET

;wrapper on rep movsq
;it handles overlapping memory
;doesn't mess up register states
;params:
;   rcx = QWORDS to mov
;   rsi = source offset
;   rdi = destination offset
;returns: none
movMemOverlap:
push r8
pushf
push rcx
push rsi
push rdi

;makes source and destination point to last element not the first
mov r8, rcx
dec r8
shl r8, 3
add rsi, r8
add rdi, r8

std
rep movsq

pop rdi
pop rsi
pop rcx
popf
pop r8
ret

;params: rcx = current index
;returns: none
pushMMDown:
    push rbx
    push rcx
    push r8
    push rsi
    push rdi

    mov rax, rcx        ;calc rsi
    mov r8, 24          ;
    mul r8              ;
    add rax, MM_ENTRIES ;
    mov rsi, rax        ;
    mov rdi, rsi        ;calc rdi
    add rdi, 24         ;
    xor rbx, rbx        ;0 rbx
    mov ebx, [MM_SIZE]  ;increment mm size
    inc ebx             ;
    mov [MM_SIZE], ebx  ;
    dec rbx             ;calc rcx
    sub rbx, rcx        ;
    mov rax, 3          ;
    mul rbx             ;
    mov rcx, rax        ;
    call movMemOverlap  ;call memMove

    pop rdi
    pop rsi
    pop r8
    pop rcx
    pop rbx
    ret

;sector align extra space
times (VBR_SECTORS * 512) - ($ - $$) db 0
