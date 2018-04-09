reg_putc = $ff00

main
        mov sp, #$1000      ; sane stack pointer
        mov d, #1           ; counter
loop
        mov c, #0           ; string pointer         

        mov a, d            ; test fizz
        mod a, #3
        equ a, #0
        ift
        mov c, fizz

        mov a, d            ; test buzz
        mod a, #5
        equ a, #0
        ift
        mov c, buzz
        
        mov a, d            ; test fizzbuzz
        mod a, #15
        equ a, #0
        ift
        mov c, fizzbuzz

        push continue       ; will call function
        equ c, #0            
        ift
        mov c, d
        ift                 ; no fizz or buzz, print num
        mov pc, print_num
        iff                 ; print fizz or buzz
        mov pc, print

continue
        mov reg_putc, #'\n' ; newline
        add d, #1
        gtt d, #100         ; loop until d > 100
        iff
        mov pc, loop
        mov $ffff, #1       ; terminate

print   equ *c, #0        ; test if char is 0
        ift
        pop pc            ; return if 0
        mov reg_putc, *c  ; write a char
        add c, #1         ; inc pointer
        mov pc, print     ; loop


print_num
        mov b, #$400
        mov *b, #0        ; null terminator
print_num_loop
        sub b, #1         ; move pointer backwards
        mov a, c          ; construct digit from c
        mod a, #10
        add a, #'0'
        mov *b, a         ; write digit
        div c, #10        ; move next digit to 1's place
        equ c, #0         ; if c != 0, loop
        iff
        mov pc, print_num_loop
        mov c, b
        mov pc, print     ; print constructed string

fizz    .data "fizz\0"
buzz    .data "buzz\0"
fizzbuzz.data "fizzbuzz\0"
