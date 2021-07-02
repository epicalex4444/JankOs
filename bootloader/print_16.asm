;params: bx = address of null terminated string
;returns: none
print_16:
    push ax          ;
    mov ah, 0xE      ;load display char function
    .loop:           ;
        mov al, [bx] ;load char into al
        test al, al  ;test if al is 0
        jz .exit     ;if 0 exit
        int 0x10     ;call bios display char interupt
        inc bx       ;point to next char
        jmp .loop    ;
    .exit:           ;
        pop ax       ;
        ret          ;
