reg_putc = $ff00

;; simple hello, world in (still being designed) hz16
;; uses a loop and subroutine to print null-terminated string
;; tests some basic features of this assembler and emulator
main
        mov sp, #$1000    ; sane stack pointer
        mov c, hello      ; call printing function
        push exit
        mov pc, print_string
exit
        mov $ffff, #1     ; exit program

;; print a null-terminated string pointed to by c
;; uses: a, c
print_string
loop    mov a, *c         ; *c means use c as address
        equ a, #0         ; test if 0
        ift
        pop pc            ; return if 0
        mov reg_putc, a   ; write a char
        add c, #1         ; inc pointer
        mov pc, loop      ; loop

hello
        .data 'hello, world', $0a, 0

;; scratch pad ;;

;; I have two more address mode slots available.
;; could be used for fifth general register.
;; could be used for always-zero register for comparisons
;; could store extra arithmetic data, like high byte of multiply, remainder of division, addition overflow

;; what to do with extra nibble?
;; could be used as a bank for addresses
;; could be used as conditional data, and replace iff and ift with something
