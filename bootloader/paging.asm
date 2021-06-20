;sets up identity paging
;identity paging is a 1:1 for real memory and virtual memory
;not very good paging because it is comparatively easy to setup
;paging can be improved later by the kernel

;basics of paging
;the cr3 register points to the pml4(pag map level 4)
;the pml4 points to the pdpts(page directory pointer table)
;the pdt points to the pdts(page directory table)
;pdts point to the pts(page table)
;the pts point to physical memory

;params: none
;returns: none
setup_paging:
    push eax
    push ebx
    push ecx
    push edi

    ;clear tables
    mov edi, 0x1000 ;start address
    mov cr3, edi    ;the cpu uses cr3 to find the page directory base
    xor eax, eax    ;mov eax, 0
    mov ecx, 4096   ;4096 repitions
    rep stosd       ;load eax, ecx times into address edi, edi inc each time
    mov edi, cr3    ;set edi back the the base

    ;assign 1 entry for pml4, pdpt and pdt
    ;readable/wirteable and present bits are also set for each
    mov DWORD [edi], 0x2003
    add edi, 0x1000
    mov DWORD [edi], 0x3003
    add edi, 0x1000
    mov DWORD [edi], 0x4003
    add edi, 0x1000

    ;assign 512 entiers in the dt which map directly to physical memory
    ;readable/wirteable and present bits are set for every entry
    mov ebx, 0x00000003      ;base alue to set in each entry
    mov ecx, 512             ;512 iterations
    .setEntry:               ;
        mov DWORD [edi], ebx ;set entry
        add ebx, 0x1000      ;point to the next step in physical memory
        add edi, 8           ;set the next entry location
        loop .setEntry       ;

    ;enable paging by set the pae bit in cr4
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    pop edi
    pop ecx
    pop ebx
    pop eax
    ret
