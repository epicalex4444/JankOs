;mode: 16 bit
;params: bx = address of null terminated string
;returns: none
print_16:
    push ax
    push bx
    push cx
    push dx
    push es

    ;to display char write at 0xB8000 + 0x02 * (row * 0x50 + col)
    ;write 2 bytes first is the style, 2nd is the char
    ;style white on black = 0x0F
    ;because the address is to large for 16 but use (es)segment register
    ;address es:bx = es << 4 + bx

    mov dx, 0xB800         ;
    mov es, dx             ;load 0xB800 into the segment register
    mov dh, 0x0F           ;load white on black style
    call get_cursor_16     ;
    shl ax, 0x0001         ;multiply on 2 because vga uses 2 bytes per char
    .loop:                 ;
        mov dl, [bx]       ;move the charecter into dl
        test dl, dl        ;check if char is 0 which means end of string
        jz .exit           ;
        cmp dl, 0x0A       ;check for newline char
        jz .newline        ;
        push bx            ;
        mov bx, ax         ;mov vga memory to bx, only regesiter bx works for this
        mov [es:bx], dx    ;write char into video memory
        pop bx             ;
        inc bx             ;next char
        add ax, 0x0002     ;next memory location write
        jmp .loop          ;
    .newline:              ;
        push dx            ;
        mov cx, ax         ;copy memory address for later
        mov dl, 0xA0       ;load divisor
        div dl             ;divide, ah=remainder, al=quotient
        shr ax, 0x08       ;make ax = only the remainder
        sub cx, ax         ;minus remainder from address(makes x = 0)
        add cx, 0xA0       ;move down 1 line
        mov ax, cx         ;move memory adress back to ax
        inc bx             ;next char
        pop dx             ;
        jmp .loop          ;
    .exit:                 ;
        shr ax, 0x0001     ;divide vga memory address by 2
        mov bx, ax         ;mov it into bx
        call set_cursor_16 ;set the cursor to where it should be
        pop es             ;
        pop dx             ;
        pop cx             ;
        pop bx             ;
        pop ax             ;
        ret                ;

;mode: any
;params: none
;returns: ax = cursor pos
get_cursor_16:
    push dx

    ;cursor low is port 0x03D4, index 0x0F
    ;cursor high is port 0x03D4, index 0x0E
    ;to use the port output the index then
    ;use port 0x03D5 to set/read the value

    mov dx, 0x03D4 ;load port
    mov al, 0x0E   ;load index
    out dx, al     ;output index for cursor high
    mov dx, 0x03D5 ;load port
    in al, dx      ;input cursor high
    shl ax, 0x0008 ;move to the high register
    mov dx, 0x03D4 ;load port
    mov al, 0x0F   ;load index
    out dx, al     ;output index for cursor low
    mov dx, 0x03D5 ;load port
    in al, dx      ;input cursor low

    pop dx
    ret

;mode: any
;params: bx = cursor pos
;returns: none
set_cursor_16:
    push ax
    push bx
    push dx

    ;cursor low is port 0x03D4, index 0x0F
    ;cursor high is port 0x03D4, index 0x0E
    ;to use the port output the index then
    ;inc the port to set/read the value

    mov dx, 0x03D4 ;load port
    mov al, 0x0F   ;load index
    out dx, al     ;output index for cursor low
    mov dx, 0x03D5 ;load port
    mov al, bl     ;move bl into al(only al works)
    out dx, al     ;output cursor low
    mov dx, 0x03D4 ;load port
    mov al, 0x0E   ;load index
    out dx, al     ;output index for cursor high
    mov dx, 0x03D5 ;load port
    mov al, bh     ;move bl into al(only al works)
    out dx, al     ;output cursor high
    
    pop dx
    pop bx
    pop ax
    ret
