;params: none
;returns: none
detect_long_mode:
    push eax
    push ebx
    push ecx
    push edx

    ;first we must check cpuid is available
    ;then we need to check if cpuid extended functions are available
    ;then we can check for long mode

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
    jz cpuid_error   ;
    push eax         ;
    popfd            ;restore previous flags register

    ;extended functions check
    ;call cpuid and check if eax is less than 0x80000001
    ;if it is less there are no extended functions
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb ext_funcs_error

    ;long mode check
    ;call extended functions cpuid and test if the 
    ;long mode bit is set if not set the is no long mode
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz long_mode_error

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

cpuid_error:
    mov edx, cpuid_error_str
    call print_32
    jmp $

ext_funcs_error:
    mov edx, ext_funcs_str
    call print_32
    jmp $

long_mode_error:
    mov edx, long_mode_error_str
    call print_32
    jmp $

cpuid_error_str:
    db "CPUID Error", 0x00

ext_funcs_str:
    db "CPUID Extended Functions Error"

long_mode_error_str:
    db "Long Mode Error", 0x00
