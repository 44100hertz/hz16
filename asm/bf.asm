;; brainfuck interpreter in hz16
;; uses stack to store brace stack for bf code
;; keeps constants in b and d to reduce program size
main
        mov sp, #$1000
        mov a, sp             ; stack pointer goal (for skipping)
        mov b, #1             ; everything in bf adds or subs 1 lol
        mov c, #$8000         ; tape ptr
        mov d, next           ; lots of jumps to "next" as well
        mov e, program        ; program ptr
loop
        neq *e, #'['
        | mov pc, no_push_pos
push_pos
        push e                ; push pos to stack
        mov a, sp             ; set goal to stack pointer
        eq *c, 0              ; if cell is zero, enable skip
        | sub a, b
        mov pc, d
no_push_pos
        gt sp, a              ; stack pointer goal set
        | mov $ff00, #'\n'
        | mov pc, skip        ; skip executing meaningful stuff

        eq *e, #'>'           ; move tape pointer
        | add c, b
        | mov pc, d
        eq *e, #'<'
        | sub c, b
        | mov pc, d
        eq *e, #'+'           ; inc/dec tape at pointer
        | add *c, b
        | mov pc, d
        eq *e, #'-'
        | sub *c, b
        | mov pc, d
        eq *e, #'.'           ; write char
        | mov $ff00, *c
        | mov pc, d
        eq *e, #','           ; TODO: read char
        | mov pc, d
skip
        eq *e, #']'
        | sub sp, b           ; pseudo-pop stack pointer
        | neq *c, #0          ; loop if cell nonzero
        | mov e, *sp          ; put execution back at loop start
        | add sp, b           ; put sp to where it was
next
        and *c, #$ff

        add e, b              ; move to next tape pos
        eq *e, #0
        | mov $ffff, b
        mov pc, loop

program .data "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.", 0
