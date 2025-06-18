section .text
global desat


;   [ebp+8]  - pointer to BMP file
;   [ebp+12] - desaturation level (0-64)
;   [ebp -4] - padding (bytes)
;   [ebp - 8] - width (pixels)
;   [ebp - 12] - width (bytes)
;   
desat:
    push    ebp
    mov     ebp, esp
    sub     esp, 16                 
    

    push    esi
    push    ebx
    push    edi



    mov     esi, [ebp+8]            ;  pointer to BMP file
    ; mov     edi, esi                ; EDI = copy of pointer

check_level:
    mov     eax, [ebp + 12]         ;  level
    cmp     eax, 64                 
    ja      fin                     ; if level > 64, end programm
    cmp     eax, 0                  
    jle     fin                     ; if level <= 0, end programm, no need to do anything

read_header:
    mov     dl, [esi + 0x1C]        ;  bits per pixel
    cmp     dl, 24                  ; Only support 24bpp
    jne     fin

    ; Calculate image dimensions
    mov     ebx, [esi + 0x12]       ; width in pixels
    mov     [ebp-8], ebx            ; width (pixels)
    lea     ebx, [ebx + ebx*2]      ;  width in bytes (width * 3)
    
calc_stride:
    ;  stride = (image_width_in_pixels * bytes_per_pixel + 3) & ~3
    mov     edx, ebx
    add     edx, 3
    and     edx, -4                 ; stride (aligned to 4 bytes)
    
    sub     edx, ebx                ; padding = stride - width (bytes)
    mov     [ebp-4], edx            ; padding (bytes)
    mov     [ebp-12], ebx           ; width (bytes)
    
    mov     ebx, [esi + 0x16]       ; height
    mov     [ebp-16], ebx           ;  height

to_first_pixel:
    ; moves esi to first pixel
    mov     ebx, [esi + 0xA]        ; pixel offset
    add     esi, ebx                ; ESI points to first pixel

    ; Initialize row counter
    mov     edi, [ebp-16]           ;height (rows remaining)

row_loop:
    mov     ecx, [ebp-8]            ;  width (pixels remaining)

pixel_loop:
    ; new_color = ((64 - level) * original_color + level * gray) / 64
    ; gray = (R + G + B) / 3
    xor     ebx, ebx                ; ebx = 0
    
    
    movzx   eax, byte [esi+0]       ; B
    add     ebx, eax
    movzx   eax, byte [esi+1]       ; G
    add     ebx, eax
    movzx   eax, byte [esi+2]       ; R
    add     ebx, eax                ; EBX = R + G + B

    ; Divide by 3
    mov     eax, ebx                ;  sum
    shr     eax, 2                  ;  sum/4
    add     ebx, eax                ;  sum + sum/4
    shr     ebx, 2                  ; ebx =  (sum + sum/4)/4 +-= sum/3

blue:
    mov     eax, [ebp + 12]         ;  level
    movzx   edx, byte [esi]         ; original blue value
    mov     ah, 64
    sub     ah, al                  ; al = 64 - level
    mov     al, ah
    mul     dl                      ; ax = (64-level)*original_color
    push    eax
    
    mov     eax, [ebp + 12]         ; level
    mul     ebx                     ; eax = level*gray
    
    pop     edx
    add     eax, edx                ; eax = (64-level)*original + level*gray
    shr     eax, 6                  ; eax = ((64 - level) * original_color + level * gray) / 64
    mov     [esi], al            

green:
    mov     eax, [ebp + 12]         ;  level
    movzx   edx, byte [esi + 1]     ; original green value
    mov     ah, 64
    sub     ah, al                  ; al = 64 - level
    mov     al, ah
    mul     dl                      ; ax = (64-level)*original_color
    push    eax
    
    mov     eax, [ebp + 12]         ; level
    mul     ebx                     ; eax = level*gray
    
    pop     edx
    add     eax, edx                ; eax = (64-level)*original + level*gray
    shr     eax, 6                  ; eax = ((64 - level) * original_color + level * gray) / 64
    mov     [esi + 1], al    

red:
    mov     eax, [ebp + 12]         ;  level
    movzx   edx, byte [esi+2]       ; original red value
    mov     ah, 64
    sub     ah, al                  ; al = 64 - level
    mov     al, ah
    mul     dl                      ; ax = (64-level)*original_color
    push    eax
    
    mov     eax, [ebp + 12]         ; level
    mul     ebx                     ; eax = level*gray
    
    pop     edx
    add     eax, edx                ; eax = (64-level)*original + level*gray
    shr     eax, 6                  ; eax = ((64 - level) * original_color + level * gray) / 64
    mov     [esi +2], al    

next_pixel:
    add     esi, 3                  ; next pixel (3 bytes per pixel)
    dec     ecx                     ; pixels_to_change -= 1
    jnz     pixel_loop              ; continue row if more pixels

next_row:
    mov     edx, [ebp-4]            ;padding (bytes)
    add     esi, edx                ; Skip padding


    dec     edi                     ; rows = rows - 1
    jnz     row_loop                ; if rows > 0, print next row

fin:

    pop     edi
    pop     ebx
    pop     esi
 
    mov     esp, ebp
    pop     ebp
    ret