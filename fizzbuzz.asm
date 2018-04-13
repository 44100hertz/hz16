reg_putc = $ff00

        mov pc, main
        mov sp, #$1000

fizz    .data "fizz", 0
buzz    .data "buzz", 0

main
        mov d, #1             ; counter
loop
        mov c, #0             ; string pointer, 0 means print num
        mov a, d              ; check fizz
        mod a, #3
        eq a, #0
        | mov c, fizz
        | call print
        mov a, d              ; check buzz
        mod a, #5
        eq a, #0
        | mov c, buzz
        | call print
        eq c, #0              ; no fizzbuzz
        | mov c, d
        | call print_num
        mov reg_putc, #'\n'
        neq d, #100           ; loop
        add d, #1
        | mov pc, loop

        mov $ffff, #1

;; copy chars into putc until 0
;; uses: c
print
        eq *c, #0             ; check for null terminator
        | pop pc
        mov reg_putc, *c      ; print char
        add c, #1             ; advance pointer
        mov pc, print         ; print next

;; extract digits from number c into $400 downwards
;; returns pointer to string in b
;; uses: a, b, c
print_num
        mov b, #$400          ; init string pointer
        mov *b, #0            ; null terminator
print_num_loop
        sub b, #1             ; dec pointer
        mov a, c
        mod a, #10            ; clamp to digit
        add a, #'0'           ; move into ascii
        mov *b, a             ; place in string
        div c, #10
        neq c, #0
        | mov pc, print_num_loop
        mov c, b
        mov pc, print
