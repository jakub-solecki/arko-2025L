section .text
global desat

; Function: desat
; Parameters:
;   [ebp+8]  - pointer to BMP file
;   [ebp+12] - desaturation level (0-64)
desat:
    ; Prologue
    push    ebp
    mov     ebp, esp
    sub     esp, 16                 ; Allocate space for local variables
    
    ; Save registers
    push    esi
    push    ebx
    push    edi

    ; Set up pointers
    mov     esi, [ebp+8]            ; ESI = pointer to BMP file
    mov     edi, esi                ; EDI = copy of pointer

    ; Validate desaturation level
    mov     eax, [ebp + 12]         ; EAX = level
    cmp     eax, 64                 ; Check if level > 64
    ja      fin                    
    cmp     eax, 0                  ; Check if level <= 0
    jle     fin

    ; Read BMP header
    mov     dl, [esi + 0x1C]        ; DL = bits per pixel
    cmp     dl, 24                  ; Only support 24bpp
    jne     fin

    ; Calculate image dimensions
    mov     ebx, [esi + 0x12]       ; EBX = width in pixels
    mov     [ebp-8], ebx            ; Store width
    lea     ebx, [ebx + ebx*2]      ; EBX = width in bytes (width * 3)
    
    ; Calculate stride (width + padding)
    mov     edx, ebx
    add     edx, 3
    and     edx, -4                 ; EDX = stride (aligned to 4 bytes)
    
    sub     edx, ebx                ; EDX = padding bytes
    mov     [ebp-4], edx            ; Store padding
    mov     [ebp-12], ebx           ; Store width in bytes
    
    mov     ebx, [esi + 0x16]       ; EBX = height
    mov     [ebp-16], ebx           ; Store height

    ; Set up pixel pointer
    mov     ebx, [edi + 0xA]        ; EBX = pixel offset
    add     esi, ebx                ; ESI points to first pixel

    ; Initialize row counter
    mov     edi, [ebp-16]           ; EDI = height (rows remaining)

row_loop:
    ; Initialize column counter
    mov     ecx, [ebp-8]            ; ECX = width (pixels remaining)

pixel_loop:
    ; Calculate gray value (R + G + B) / 3
    xor     ebx, ebx                ; EBX will hold sum
    
    ; Sum RGB components
    movzx   eax, byte [esi+0]       ; B
    add     ebx, eax
    movzx   eax, byte [esi+1]       ; G
    add     ebx, eax
    movzx   eax, byte [esi+2]       ; R
    add     ebx, eax                ; EBX = R + G + B

    ; Divide by 3 using shift operations
    mov     eax, ebx                ; EAX = sum
    shr     eax, 2                  ; EAX = sum/4
    add     ebx, eax                ; EBX = sum + sum/4
    shr     ebx, 2                  ; EBX = (sum + sum/4)/4 ≈ sum/3

    ; Process blue channel
    mov     eax, [ebp + 12]         ; EAX = level
    movzx   edx, byte [esi]         ; EDX = original blue value
    mov     ah, 64
    sub     ah, al                  ; AH = 64 - level
    mov     al, ah
    mul     dl                      ; AX = (64-level)*original_color
    push    eax
    
    mov     eax, [ebp + 12]         ; EAX = level
    mul     ebx                     ; EAX = level*gray
    
    pop     edx
    add     eax, edx                ; EAX = (64-level)*original + level*gray
    shr     eax, 6                  ; Divide by 64
    mov     [esi], al               ; Store new blue value

    ; Process green channel
    mov     eax, [ebp + 12]         ; EAX = level
    movzx   edx, byte [esi+1]       ; EDX = original green value
    mov     ah, 64
    sub     ah, al                  ; AH = 64 - level
    mov     al, ah
    mul     dl                      ; AX = (64-level)*original_color
    push    eax
    
    mov     eax, [ebp + 12]         ; EAX = level
    mul     ebx                     ; EAX = level*gray
    
    pop     edx
    add     eax, edx                ; EAX = (64-level)*original + level*gray
    shr     eax, 6                  ; Divide by 64
    mov     [esi+1], al             ; Store new green value

    ; Process red channel
    mov     eax, [ebp + 12]         ; EAX = level
    movzx   edx, byte [esi+2]       ; EDX = original red value
    mov     ah, 64
    sub     ah, al                  ; AH = 64 - level
    mov     al, ah
    mul     dl                      ; AX = (64-level)*original_color
    push    eax
    
    mov     eax, [ebp + 12]         ; EAX = level
    mul     ebx                     ; EAX = level*gray
    
    pop     edx
    add     eax, edx                ; EAX = (64-level)*original + level*gray
    shr     eax, 6                  ; Divide by 64
    mov     [esi+2], al             ; Store new red value

    ; Move to next pixel
    add     esi, 3                  ; Next pixel (3 bytes per pixel)
    dec     ecx                     ; Decrement pixel counter
    jnz     pixel_loop              ; Continue row if more pixels

    ; Handle padding at end of row
    mov     edx, [ebp-4]            ; EDX = padding bytes
    add     esi, edx                ; Skip padding

    ; Move to next row
    dec     edi                     ; Decrement row counter
    jnz     row_loop                ; Continue if more rows

fin:
    ; Restore registers
    pop     edi
    pop     ebx
    pop     esi
    
    ; Epilogue
    mov     esp, ebp
    pop     ebp
    ret