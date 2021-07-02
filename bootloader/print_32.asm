;params: edx = address of null terminated string
;returns: none
print_32:
    push eax
    push ebx
    push cx
    push dx

    ;to display char write at 0xB8000 + 0x02 * (row * 0x50 + col)
    ;write 2 bytes first is the style, 2nd is the char
    ;style white on black = 0x0F
    ;because the address is to large for 16 but use (es)segment register
    ;address es:bx = es << 4 + bx

    mov ch, 0x0F           ;load white on black style
    mov ebx, 0xB8000       ;
    mov eax, 0             ;
    call get_cursor_32     ;
    shl ax, 0x0001         ;multiply on 2 because vga uses 2 bytes per char
    add ebx, eax           ;
    .loop:                 ;
        mov cl, [edx]      ;move the charecter into dl
        test cl, cl        ;check if char is 0 which means end of string
        jz .exit           ;
        mov [ebx], cx      ;write char into video memory
        inc edx            ;next char
        add ebx, 2         ;next memory location write
        jmp .loop          ;
    .exit:                 ;
        sub ebx, 0xB8000   ;
        shr ebx, 1         ;
        call set_cursor_32 ;set the cursor to where it should be
        pop dx             ;
        pop cx             ;
        pop ebx            ;
        pop eax            ;
        ret                ;

;params: none
;returns: ax = cursor pos
get_cursor_32:
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

;params: bx = cursor pos
;returns: none
set_cursor_32:
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
