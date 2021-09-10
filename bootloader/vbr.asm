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
;read fs to find kernel
;generate memory map
;load kernel to temporary spot
;get into long mode
;   identity paging
;   basic gdt
;   set long mode bits
;check kernel can be moved to KERNEL
;move kernel to KERNEL
;update mM to make sure the kernel is in reserved memory
;update segment registers
;disble bios interupts
;jmp to the kernel

;controls length of file and memory offsets
;if changing this also need to change kernel.bin lba in the Makefile by the same amount
VBR_SECTORS: equ 4

;file header offsets
FILE_OFFSET: equ 0x7C00 + VBR_SECTORS * 0x200
FILE_SECTORS: equ FILE_OFFSET
FILE_FILE_NAME: equ FILE_OFFSET + 8

;folder header offsets
FOLDER_OFFSET: equ FILE_OFFSET + 0x200
FOLDER_SECTORS: equ FOLDER_OFFSET
FOLDER_FILE_NUM: equ FOLDER_OFFSET + 4
FOLDER_FILE_LBA: equ FOLDER_OFFSET + 14

;memory map offsets
MM_OFFSET: equ 0x5000
MM_SIZE: equ MM_OFFSET
MM_ENTRIES: equ MM_OFFSET + 2

;page tables offsets
PAGE_TABLES_OFFSET: equ 0x1000
PML4: equ PAGE_TABLES_OFFSET
PDP: equ PML4 + 0x1000
PD: equ PDP + 0x1000
PT: equ PD + 0x1000

;kernel offsets
TEMP_KERNEL: equ FILE_OFFSET
KERNEL: equ 0x100000

[org 0x7C00]
[bits 16]

;save partition entry and boot drive in memory
mov [partitionEntry], si
mov [bootDrive], dl

;load the rest of the vbr
mov ah, 0x42
mov si, dap
int 0x13
jc vbr_error

;setup dap to load 1st sector of the the root folder
mov WORD [dap.sectors], 1            ;set dap.sectors to 1
mov WORD [dap.offset], FOLDER_OFFSET ;set dap.offset to folder.offset
mov si, [partitionEntry]             ;move partion entry into si
add si, 8                            ;point to partitionEntry.lba
mov ebx, [si]                        ;mov lba into ebx
add ebx, VBR_SECTORS                 ;add vbr sectors to lba(root folder is directly after the vbr)
jno noOverflow                       ;if overflow increment lba.upper by 1
mov DWORD [dap.lba_upper], 1         ;same as setting to 1 here since it is always 0 before
noOverflow:                          ;
mov [dap.lba_lower], ebx             ;set lower lba

;load 1st sector of root folder
mov ah, 0x42
mov si, dap
int 0x13
jc error.root_folder_sector1

;check fileNum >= 1
mov eax, [FOLDER_FILE_NUM]
cmp eax, 1
jl error.no_files

;set up dap to load the whole root folder
mov ax, [FOLDER_SECTORS]
mov [dap.sectors], ax

;load whole root folder
mov ah, 0x42
mov si, dap
int 0x13
jc error.root_folder

;setup dap for loading file headers
mov WORD [dap.sectors], 1
mov WORD [dap.offset], FILE_OFFSET

;search for kernel.bin file
;returns: bx = lba of kernel.bin
mov ecx, [FOLDER_FILE_NUM]   ;set loop counter to fileNum
mov bx, FOLDER_FILE_LBA      ;set bx to address of the lba of the first file
mov di, KERNEL_BIN           ;set di to kernel.bin string address
fileLoop:                    ;
    mov edx, [bx]            ;move file.lba_lower into edx
    mov [dap.lba_lower], edx ;set dap.lba_lower to file lba
    add bx, 4                ;point to upper lba
    mov edx, [bx]            ;move file.lba_upper into edx
    mov [dap.lba_upper], edx ;set dap.lba_upper to file lba
    mov ah, 0x42             ;set ah to bios code for extended read
    mov dl, [bootDrive]      ;set dl to boot drive
    mov si, dap              ;set si to dap address
    int 0x13                 ;call extended read interupt
    jc error.file            ;
    mov si, FILE_FILE_NAME   ;set si to fileName string address
    call strCmp              ;if fileName == kernel.bin
    jc .end                  ;
    add bx, 4                ;point to next the lba of the next file
    loop fileLoop            ;
    jmp error.kernel_file    ;loop finished without finding a file named kernel.bin
    .end:                    ;
    sub bx, 4                ;subtract 4 from to point to the start of the file lba

;setup dap for loading the kernel
;returns: edx = kernel.bin sectors
mov WORD [dap.offset], TEMP_KERNEL ;set dap.offset to a temporary spot to load the kernel(kernel is moved later)
mov eax, [bx]                      ;move file.lba_lower into eax
add bx, 4                          ;point to file.lba_upper
mov ecx, [bx]                      ;move file.lba_lower into ecx
inc eax                            ;point to next sector which is kernel.bin(file header is always 1 sector)
jno noOverflow2                    ;if over increment file.lba_upper
inc ecx                            ;
jo error.kernel_lba                ;if this overflows it's an error
noOverflow2:                       ;
mov [dap.lba_lower], eax           ;set dap.lba_lower to kernel.lba_lower
mov [dap.lba_upper], ecx           ;set dap.lba_upper to kernel.lba_upper
mov edx, [FILE_SECTORS]            ;load kernel.bin sectors into edx(fits in dx, edx used to 0 top half)
mov [dap.sectors], dx              ;set dap.sectors to kernel.sectors

;store kernel size for later(multiple by 512 to store in bytes)
shl edx, 9
mov [kernelBytes], edx

;load kernel
mov ah, 0x42
mov dl, [bootDrive]
mov si, dap
int 0x13
jc error.kernel_load

;cpuid check
;flips id bit in flags register if it stays flippd it cpuid is supported
pushfd             ;move flags into eax via stack
pop eax            ;
mov ecx, eax       ;copy flags into ecx
xor eax, 1 << 21   ;flip id bit
push eax           ;move flags back into flags register via stack
popfd              ;
pushfd             ;move flags into eax via stack
pop eax            ;
xor eax, ecx       ;check if id bit was flipped
je error.cpuid     ;
push ecx           ;move flags back into flags register via stack
popfd              ;

;extended functions check
mov eax, 0x80000000 ;this value means get highest extended function
cpuid               ;
cmp eax, 0x80000000 ;check if long mode check extended function is available
je error.ext_funcs  ;

;long mode check
mov eax, 0x80000001 ;this value is used to check if long mode is supported
cpuid               ;
test edx, 1 << 29   ;test if long mode bit is set
je error.long_mode  ;

;jump to extended vbr space
jmp extendedVbr

;error handling for loading vbr
;this error handling needs to be in first sector
;but we can't fit all the error handling in the first sector
VBR_LOAD_ERROR: db "couldn't load vbr", 0
vbr_error:
    mov bx, VBR_LOAD_ERROR
    call print_string_16
die:
    hlt
    jmp die

;params: bx = address of null terminated string
;returns: none
print_string_16:
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
;   si = address of null terminated string 1
;   di = address of null terminated string 2
;returns: cf set on match else unset
strCmp:
    pusha              ;
    .loop:             ;
        mov cl, [si]   ;move str1 char into cl
        mov ch, [di]   ;move str2 char into ch
        cmp cl, ch     ;check whether the chars are equal
        jne .notEqual  ;exit not equal
        test cl, cl    ;if cl = 0
        jz .equal      ;
        inc si         ;point to next str1 char
        inc di         ;point to next str2 char
        jmp .loop      ;
    .notEqual:         ;
        clc            ;clear carry flag
        jmp .exit      ;
    .equal:            ;
        stc            ;set carry flag
    .exit:             ;
        popa           ;
        ret            ;

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

;memory variables
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
mov DWORD [PML4], PDP + 3 ;point PML4 to PDP
mov DWORD [PDP], PD + 3   ;point PDP to PD
mov DWORD [PD], PT + 3    ;point PD to PT
mov edi, PT               ;set edi to pt address
mov ebx, 0x00000003       ;initial value to set in pt(bits 1 and 2 will be set for every entry)
mov ecx, 512              ;loop to fill 512 iterations pt
pagingLoop:               ;
    mov DWORD [edi], ebx  ;write entry into pt
    add ebx, 0x1000       ;update ebx to the next page address
    add edi, 8            ;update edi to the next pt entry
    loop pagingLoop       ;

;generate E820 memory map
mov edx, 0x534D4150           ;set edx to E820 smap code
xor si, si                    ;set dx to 0, this variable keeps count
mov di, MM_ENTRIES            ;move mm_entries address into si
xor ebx, ebx                  ;continuation value for E820, starts at 0
memoryMapLoop:                ;
    mov eax, 0xE820           ;set eax to bios code for memory map
    mov ecx, 24               ;set ecx to 24(buffer size for interupt)
    mov [es:di + 20], DWORD 1 ;force valid acpi 3.x submission by setting ~ignore bit
    int 0x15                  ;call memory map interupt
    jc error.mm               ;
    add di, 24                ;point di to next entry
    inc si                    ;increment size count
    test ebx, ebx             ;if ebx == 0(E820 return ebx = 0 when finished)
    jne memoryMapLoop         ;
    mov [MM_SIZE], si         ;set memory_map.size

;load gdt
lgdt [gdt.descriptor]

;set bits to enable long mode
;paging and protected mode bits are set similtaneousely
;this skips needing to go to protected mode first before long mode
mov eax, 10100000b  ;set cr4.PAE and cr4.PGE bits
mov cr4, eax        ;
mov ecx, 0xC0000080 ;
rdmsr               ;
or eax, 0x00000100  ;set LME bit in model specific register
wrmsr               ;
mov ebx, cr0	    ;
or ebx, 0x80000001  ;set cr0.PE and cr0.PG bits
mov cr0, ebx        ;

;flush instruction cache
;so we don't execute real mode code in long mode
;also sets cs register to our gdt entry
jmp gdt.code:longMode

;error handling, prints error messages then hangs indefinately
error:
    .root_folder_sector1:
        mov bx, ROOT_FOLDER_LOAD_ERROR1
        jmp .end
    .root_folder:
        mov bx, ROOT_FOLDER_LOAD_ERROR2
        jmp .end
    .no_files:
        mov bx, NO_FILES_ERROR
        jmp .end
    .file:
        mov bx, FILE_ERROR
        jmp .end
    .kernel_file:
        mov bx, NO_KERNEL_ERROR
        jmp .end
    .kernel_lba:
        mov bx, KERNEL_LBA_ERROR
        jmp .end
    .kernel_load:
        mov bx, KERNEL_LOAD_ERROR
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
        call print_string_16
        jmp die

;strings
ROOT_FOLDER_LOAD_ERROR1: db "couldn't load 1st sector of root folder", 0
ROOT_FOLDER_LOAD_ERROR2: db "couldn't load root folder", 0
NO_FILES_ERROR:          db "no files in root folder", 0
FILE_ERROR:              db "failed to load file in root folder", 0
NO_KERNEL_ERROR:         db "kernel.bin not in root folder", 0
KERNEL_LBA_ERROR:        db "kernel.bin lba too large", 0
KERNEL_LOAD_ERROR:       db "kernel failed to load", 0
CPUID_ERROR:             db "cpuid error", 0
EXT_FUNCS_ERROR:         db "extended function not supported", 0
LONG_MODE_ERROR:         db "long mode not supported", 0
MM_ERROR:                db "memory map error", 0
KERNEL_MM_ERROR:         db "kernel can not fit into memory", 0
KERNEL_BIN:              db "kernel.bin", 0

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

;disable interupts(bios interupts can't be used in long mode)
cli

;update segment registers to out gdt entry(cs done before)
mov ax, gdt.data
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

;check if kernel fits into memory map
;returns:
;   rcx = index of entry
;   rsi = offset of entry
xor rcx, rcx            ;set rcx to 0
mov cx, [MM_SIZE]       ;move mm.size into cx
mov rsi, MM_ENTRIES     ;mov mm.entries address into rsi
xor r8, r8              ;set r8 to 0
mov r8d, [kernelBytes]  ;mov kernelBytes into r8
kernelLoop:             ;
    mov r9, [rsi]       ;move mm.offset into r9
    add rsi, 8          ;point to mm.length
    mov r10, [rsi]      ;move mm.length into r10
    add rsi, 8          ;point to mm.type
    mov r11, [rsi]      ;move mm.type into r11
    add rsi, 4          ;point to mm.acpi
    mov r12, [rsi]      ;move mm.acpi into r12
    add rsi, 4          ;point to next entry
    cmp r11d, 1         ;if mm.type != 1
    jne .invalid        ;
    test r12d, 1        ;if mm.acpi & 1
    je .invalid         ;
    cmp r9, KERNEL      ;if mm.offset > kernel.offset
    jg .invalid         ;
    add r8, KERNEL      ;add kernel.length to kernel.offset
    cmp r10, r8         ;if mm.length < kernel.length + kerneloffset
    jl .invalid         ;
    jmp .valid          ;passed all checks kernel can fit in this entry
    .invalid:           ;
    loop kernelLoop     ;
    jmp kernel_mm_error ;loop ended without finding a valid entry
    .valid:             ;
    dec rcx             ;decrement rcx to make it the index of the valid entry
    sub rsi, 24         ;decrement rsi to make it the offset of the valid entry

;reserve the memory the kernel is in
;mmb = memory map below kernel
;mmk = memory map kernel
;mma = memory map above kernel
mov r8, KERNEL          ;move kernel.offset into r8
cmp r8, [rsi]           ;if mmk.offset == kernel.offset
je notSplitBelow        ;
call pushMMDown         ;move entries down(duplicating the current entry)
inc rcx                 ;update index(pushMMDown uses the index)
sub r8, [rsi]           ;set r8 to kernel.offset - mmb.offset
mov [rsi + 8], r8       ;mmb.length = kernel.offset - mmb.offset
add rsi, 24             ;point to mmk
mov QWORD [rsi], KERNEL ;set mmk.offset to kernel.offset
mov r9, [rsi + 8]       ;mmk.length -= mmb.length
sub r9, r8              ;
mov [rsi + 8], r9       ;
notSplitBelow:          ;
xor r8, r8              ;set r8 to 0
mov r8d, [kernelBytes]  ;move kernel.length into r8
cmp r8, [rsi + 8]       ;if mmk.length == kernel.length
je notSplitAbove        ;
call pushMMDown         ;move entries down(duplicating the current entry)
mov [rsi + 8], r8       ;mmk.length = kernel.length
add rsi, 24             ;point to mma
mov r9, [rsi]           ;mma.offset += kernel.length
add r9, r8              ;
mov [rsi], r9           ;
mov r9, [rsi + 8]       ;mma.length -= kernel.length
sub r9, r8              ;
mov [rsi + 8], r9       ;
sub rsi, 24             ;point to mmk
notSplitAbove:          ;
add rsi, 16             ;point to mmk.type
mov DWORD [rsi], 2      ;set to reserved

;move kernel
xor rcx, rcx           ;set rcx to 0
mov ecx, [kernelBytes] ;move kernelBytes into ecx
mov rsi, TEMP_KERNEL   ;source address
mov rdi, KERNEL        ;destination address
call movMemOverlap     ;rep movsq but can handle overlaps

;jump to kernel (jumps to kernel_entry.asm)
jmp KERNEL

kernel_mm_error:
    mov ebx, KERNEL_MM_ERROR
    call print_string_64
    jmp die

;doesn't handle newlines and cursor moving but who cares
;params: ebx = address of null terminated string
;returns: none
print_string_64:
    push rdi
    push rbx
    push rax
    mov rdi, 0xB8000      ;video memory
    mov ah, 0x0F          ;white on black colours
    .loop:                ;
        mov al, [ebx]     ;load char into al
        test al, al       ;test if al is 0
        jz .exit          ;if 0 exit
        mov [rdi], ax     ;
        inc ebx           ;point to next char
        add rdi, 2        ;point to next video memory entry
        jmp .loop         ;
    .exit:                ;
        pop rax           ;
        pop rbx           ;
        pop rdi           ;
        ret               ;

;wrapper on rep movsq
;it handles overlapping memory
;doesn't mess up register states
;params:
;   rcx = QWORDS to mov
;   rsi = source offset
;   rdi = destination offset
;returns: none
movMemOverlap:
    pushf
    push rcx
    push rsi
    push rdi

    ;if destination is greater you need to start from the end to no override
    ;but if it is less you need to start from the start
    cmp rdi, rsi    ;if rdi > rsi
    jg .backwards   ;
    cld             ;clear direction flag
    rep movsq       ;
    jmp .end        ;
    .backwards:     ;
        push r8     ;
        mov r8, rcx ;copy rcx into r8
        dec r8      ;decrement r8
        shl r8, 3   ;multiple r8 by 8
        add rsi, r8 ;add r8 to rsi
        add rdi, r8 ;add r8 to rdi
        std         ;set direction flag(rep movsq goes backwards)
        rep movsq   ;repeat copying quadwords decrementing rcx until rcx = 0, decrements rsi and rdi as well
        pop r8      ;

    .end:
        pop rdi
        pop rsi
        pop rcx
        popf
        ret

;copies all entries down 1
;essentially duplicating entry pointed to by rsi down 1
;params:
;   rcx = current index
;   rsi = current offset
;returns: none
pushMMDown:
    push rbx
    push rcx
    push rdi

    mov rdi, rsi       ;copy rsi to rdi
    add rdi, 24        ;add 24 to rdi(moves it one entry forwards)
    xor rbx, rbx       ;set rbx to 0
    mov ebx, [MM_SIZE] ;move mm.size into ebx
    inc ebx            ;increment mm.size
    mov [MM_SIZE], ebx ;move mm.size back into memory
    dec rbx            ;decrement rbx(turns size into last index)
    sub rbx, rcx       ;subtract current index(finds entries to move)
    mov rax, 3         ;move 3 into rax
    mul rbx            ;multiply rbx by 3(ach entry is 3 quadwords)
    mov rcx, rax       ;moves result into rcx
    call movMemOverlap ;

    pop rdi
    pop rcx
    pop rbx
    ret

;sector align extra space
times (VBR_SECTORS * 512) - ($ - $$) db 0
