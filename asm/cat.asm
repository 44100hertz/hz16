loop
        mov a, $ff00
        eq a, #$-1
        | mov $ffff, #1
        mov $ff00, a
        mov pc, loop
