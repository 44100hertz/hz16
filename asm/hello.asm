reg_putc = $ff00

;; simple hello, world in (still being designed) hz16
;; uses a loop and subroutine to print null-terminated string
;; tests some basic features of this assembler and emulator
main
        mov sp, #$1000    ; sane stack pointer
        mov c, hello      ; call printing function
        call print_string
        mov $ffff, #1     ; exit program

;; print a null-terminated string pointed to by c
;; uses: c
print_string
loop    eq *c, #0         ; test if char is 0
        | pop pc          ; return if 0
        mov reg_putc, *c  ; write a char
        add c, #1         ; inc pointer
        mov pc, loop      ; loop

hello
        .data 'hello, world\n\0'
