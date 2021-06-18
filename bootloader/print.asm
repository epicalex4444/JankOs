;mode: any
;use type: call
;params: bx = address of null terminated string
;returns: none
print:
    pusha
    push es

    ;to display char write at 0xB8000 + 0x02 * (row * 0x50 + col)
    ;write 2 bytes first is the style, 2nd is the char
    ;style white on black = 0x0F
    ;because the address is to large for 16 but use (es)segment register
    ;address es:bx = es << 4 + bx

    mov dx, 0xB800
    mov es, dx ;load 0xB800 into the segment register
    mov dh, 0x0F ;load white on black style
    push bx
    call get_cursor
    shl bx, 0x0001 ;multiply on 2 because vga uses 2 bytes per char
    mov cx, bx ;save vga memory address
    pop bx
    .loop:
        mov dl, [bx] ;move the charecter into dl
        test dl, dl ;check if char is 0 which means end of string
        jz .exit
        cmp dl, 0x0A ;check for newline char
        jz .newline
        push bx
        mov bx, cx ;mov vga memory to bx, only regesiter bx works for this
        mov [es:bx], dx ;write char into video memory
        pop bx
        inc bx ;next char
        add cx, 0x0002 ;next memory location write
        jmp .loop
    .newline:
        push ax
        push dx
        mov ax, cx ;load divdedend
        mov dl, 0xA0 ;load divisor
        div dl ;divide, ah=remainder, al=quotient
        shr ax, 0x08 ;make ax = only the remainder
        sub cx, ax ;minus remainder from address(makes x = 0)
        add cx, 0xA0 ;move down 1 line
        inc bx ;next char
        pop dx
        pop ax
        jmp .loop
    .exit:
        shr cx, 0x0001
        mov bx, cx
        call set_cursor
        pop es
        popa
        ret

;mode: any
;use type: call
;params: none
;returns:
;   bx = cursor pos
get_cursor:
    push dx
    push ax

    ;cursor low is port 0x03D4, index 0x0F
    ;cursor high is port 0x03D4, index 0x0E
    ;to use the port output the index then
    ;use port 0x03D5 to set/read the value

	mov dx, 0x03D4 ;misc vga I/O port

    mov al, 0x0E
	out dx, al ;output index for cursor high
    
	inc dl
	in al, dx ;input cursor high
    
    shl ax, 8 ;move to the high register

	dec dl
	mov al, 0x0F
	out dx, al ;output index for cursor low

	inc dl
	in al, dx ;input cursor low
    
    mov bx, ax

    pop ax
    pop dx
	ret

;mode: any
;use type: call
;params:
;   bx = cursor pos
;returns: none
set_cursor:
    push ax
    push bx
    push dx

    ;cursor low is port 0x03D4, index 0x0F
    ;cursor high is port 0x03D4, index 0x0E
    ;to use the port output the index then
    ;inc the port to set/read the value

	mov dx, 0x03D4 ;misc vga I/O port

	mov al, 0x0F
	out dx, al ;output index for cursor low

	inc dl
	mov al, bl
	out dx, al ;output cursor low

	dec dl
	mov al, 0x0E
	out dx, al ;output index for cursor high
    
	inc dl
	mov al, bh
	out dx, al ;output cursor high
    
    pop dx
    pop bx
    pop ax
	ret
