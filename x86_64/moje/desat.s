    section .text
    global desat


desat:
    push    ebp
    mov     ebp, esp
    sub     esp, 12


    push    esi
    push    ebx
    push    edi
    ; push    edx
    ; push    eax
    ; push    ecx


    mov     esi, [ebp+8]        ;pointer to file
    mov     edi, esi
    mov     eax, [ebp + 12]     ; level

check_level:
    cmp    eax, 64 ; level [0; 64]
    ja     fin     

    cmp    eax, 0 ; if level <= 0 jump to fin, no need to do anything
    jle    fin


read_header:
    mov     dl, [esi + 0x1C]    ;bpp
    cmp     dl, 24              ;only bpp24 is supported
    jne     fin


    ; stride = (image_width_in_pixels * bytes_per_pixel + 3) & ~3
    mov     ebx, [esi + 0x12]   ; Width
    lea     ebx, [ebx + ebx*2]  ;width in bytes (width * 3)

    mov     edx, ebx
    add     edx, 3
    
    and     edx, -4             ; -4 = ~3   ; stride (width + padding)


    sub     edx, ebx            ; padding (bytes)

    mov     [ebp-4], edx        ; padding (bytes)
    mov     [ebp-8], ebx        ; width (bytes)
    
    ; push    edx                 ; padding

loop:


; new_color = ((64 - level) * original_color + level * gray) / 64
; gray = (R + G + B) / 3
fin:
    ; pop     ecx
    ; pop     eax
    ; pop     edx
    pop     edi
    pop     ebx
    pop     esi
    mov     esp, ebp
    pop     ebp
    ret