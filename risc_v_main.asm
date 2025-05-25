.eqv OPEN_SYSCALL,      1024
.eqv READ_SYSCALL,      63
.eqv LSEEK_SYSCALL,     62
.eqv CLOSE_SYSCALL,     57
.eqv SBRK_SYSCALL,      9
.eqv EXIT_SYSCALL,      93
.eqv PRINTSTRING_SYSCALL, 4
.eqv ASCII_OFFSET, 	48


.data

prompt_msg:
    .asciz "Podaj nazwę pliku BMP: "    # Komunikat wyświetlany użytkownikowi
header_buf:
    .space 54                          # Bufor na nagłówek BMP (54 bajty)
filename_buf:
    .space 128                         # Bufor na wczytaną nazwę pliku
err_msg:
    .asciz "Błąd otwarcia pliku\n"        # Komunikat błędu

.text
.globl main
main:
    # 1) Wyświetl prompt i wczytaj nazwę pliku
    la    a0, prompt_msg              # a0 = adres komunikatu
    li    a7, PRINTSTRING_SYSCALL
    ecall
    li    a0, 0                       # a0 = stdin
    la    a1, filename_buf            # a1 = adres bufora na nazwę
    li    a2, 64                      # a2 = maks. liczba bajtów do wczytania
    li    a7, READ_SYSCALL
    ecall

    # 2) Usuń końcowy znak '\n' z wczytanego stringa
    la    t0, filename_buf            # t0 = bieżący wskaźnik w buforze
trim:
    lb    t1, 0(t0)                   # t1 = *t0
    beqz  t1, open_file               # jeśli zero (koniec stringa), skocz
    li    t2, 10                      # kod ASCII '\n'
    beq   t1, t2, clear_nl            # jeśli '\n', nadpisz na 0
    addi  t0, t0, 1                   # inaczej idź do kolejnego znaku
    j     trim
clear_nl:
    sb    x0, 0(t0)                  # zamień '\n' na 0

open_file:
    # 3) Krótka pauza przed otwarciem (delay)
    li    t3, 50000                   # licznik pauzy
delay:
    addi  t3, t3, -1
    bnez  t3, delay

    # 4) Otwórz plik BMP
    la    a0, filename_buf            # a0 = pointer do nazwy pliku
    li    a1, 0                       # a1 = O_RDONLY
    li    a7, OPEN_SYSCALL
    ecall
    mv    s0, a0                      # s0 = fd pliku
    li    s1, -1
    beq   a0, s1, file_error         # jeśli fd==-1, błąd

    # 5) Wczytaj nagłówek BMP (54 bajty)
    mv    a0, s0                      # a0 = fd
    la    a1, header_buf             # a1 = buf
    li    a2, 54                      # a2 = liczba bajtów
    li    a7, READ_SYSCALL
    ecall

    # 6) Parsowanie szerokości (s2), wysokości (s3) i przesunięcia danych (s5)
    la    t4, header_buf             # t4 = adres nagłówka
    # width:
    lbu   s2, 18(t4)                 # s2 = byte0 width
    lbu   s3, 19(t4)
    slli  s3, s3, 8
    add   s2, s2, s3
    lbu   s3, 20(t4)
    slli  s3, s3, 16
    add   s2, s2, s3
    lbu   s3, 21(t4)
    slli  s3, s3, 24
    add   s2, s2, s3

    # height:
    lbu   s3, 22(t4)                 # s3 = byte0 height
    lbu   s4, 23(t4)
    slli  s4, s4, 8
    add   s3, s3, s4
    lbu   s4, 24(t4)
    slli  s4, s4, 16
    add   s3, s3, s4
    lbu   s4, 25(t4)
    slli  s4, s4, 24
    add   s3, s3, s4

    # data offset:
    lbu   s5, 10(t4)                 # s5 = byte0 offset
    lbu   s6, 11(t4)
    slli  s6, s6, 8
    add   s5, s5, s6
    lbu   s6, 12(t4)
    slli  s6, s6, 16
    add   s5, s5, s6
    lbu   s6, 13(t4)
    slli  s6, s6, 24
    add   s5, s5, s6

    # 7) Oblicz row_size = wyrównana szerokość wiersza (s6)
    mv    s6, s2                      # s6 = width
    li    a0, 3
    mul   s6, s6, a0                 # s6 = width*3 bajty na piksele
    addi  s6, s6, 3
    li    a0, -4
    and   s6, s6, a0                 # s6 = (width*3+3)&~3
    
    
    


