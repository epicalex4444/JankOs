;starting environment
;loaded at either 0x7C00:0x0000 or 0x0000:0x7C00 by bios
;dl = boot drive
;bios interupts enabled
;real mode
;A20 line disabled

;what this mbr does
;sets segment registers to 0
;set stack to 0x7C00
;setup screen/vga
;enable the A20 line
;bootstrap itself to 0x600
;load vbr to 0x7C00
;set es:si to bootable partition entry base
;set dl to boot drive
;jump to the vbr

[org 0x600]
[bits 16]

;set segment registers to 0
;cs done later
xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

;set stack poniter to just below
;stack grows downwards
mov sp, 0x7C00

;save boot drive(dl)
push dx

;enable A20 line
in al, 0x92
or al, 0x02
out 0x92, al

;clear screen
mov ah, 0x06
xor al, al
mov bh, 0x0F
xor cx, cx
mov dh, 0x18
mov dl, 0x4F
int 0x10

;move cursor to the top left position
mov ah, 0x02
xor bx, bx
xor dx, dx
int 0x10

;return boot drive(dl)
pop dx

;relocate self to 0x600
cld
mov cx, 0x0080
mov si, 0x7C00
mov di, 0x0600
rep movsd

;jump to relocated address
;also sets cs to 0
jmp 0:relocate
relocate:

;find bootable partition
mov si, pt1              ;set si to partition entry 1 base
mov cx, 4                ;4 iterations
partLoop:                ;
    test BYTE [si], 0x80 ;test for active bit
    jne partLoopEnd      ;found active bit exit
    add si, 0x10         ;point to next entry
    loop partLoop        ;loop
    jmp error.partition  ;error if no bootable partion found
partLoopEnd:             ;

;check for extended read
mov ah, 0x41
mov bx, 0x55AA
int 0x13
jc error.extendedRead

;save partion entry base
push si

;mov partion lba start into dap
add si, 8
mov di, dap.lba_lower
movsd

;read vbr
mov ah, 0x42
mov si, dap
int 0x13
jc error.readVbr

;return partition entry base
pop si

;check vbr boot signature
cmp WORD [0x7DFE], 0xAA55
jne error.bootSig

;jump to vbr
;dl set to boot drive
;es:si set to partition entry
jmp 0x7C00

;params: bx = address of null terminated string
;returns: none
print_string:
    pusha            ;
    mov ah, 0xE      ;display char function
    .loop:           ;
        mov al, [bx] ;load char into al
        test al, al  ;test if al is 0
        je .exit     ;if 0 exit
        int 0x10     ;call bios display char interupt
        inc bx       ;point to next char
        jmp .loop    ;
    .exit:           ;
        popa         ;
        ret          ;

;error handling
error:
    .partition:
        mov bx, PARTITION_ERROR
        jmp .end
    .extendedRead:
        mov bx, EXT_READ_ERROR
        jmp .end
    .readVbr:
        mov bx, READ_VBR_ERROR
        jmp .end
    .bootSig:
        mov bx, BOOT_SIG_ERROR
    .end:
        call print_string
    .die:
        hlt
        jmp .die

;strings
PARTITION_ERROR: db "no bootable partition", 0
EXT_READ_ERROR:  db "extended read not supported", 0
READ_VBR_ERROR:  db "failed reading the vbr", 0
BOOT_SIG_ERROR:  db "vbr missing signature", 0

;disk address packet
dap:
.size:      db 0x10
.null:      db 0
.sectors:   dw 1
.offset:    dw 0x7C00
.segment:   dw 0
.lba_lower: dd 0 ;placeholder
.lba_upper: dd 0 ;placeholder

;pad until partition table
times 436 - ($ - $$) db 0

;placeholding partition table(set later with fdisk)
uid: times 10 db 0 ;technically optional, but fdisk overrides this
pt1: times 16 db 0
pt2: times 16 db 0
pt3: times 16 db 0
pt4: times 16 db 0

;boot signature
dw 0xAA55
