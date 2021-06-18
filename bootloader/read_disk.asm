;mode: 16bit
;params: 
;   al = sectors to read, al > 0 and < 128
;   dl = drive
;returns: none
read_disk:
    push ax
    push bx
    push cx
    push dx
    push es

    mov bx, 0x0000
    mov es, bx
    mov bx, 0x7E00 ;es:bx is start read address
    mov ch, 0x00 ;cylinder
    mov dh, 0x00 ;head
    mov cl, 0x02 ;sector, start 1
    mov ah, 0x02 ;load bios sector read function
    int 0x13 ;call bios interupt
    jc disk_error

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

disk_error:
    mov bx, disk_error_str
    call print
    jmp $

disk_error_str:
    db "Disk Read Error", 0x00
