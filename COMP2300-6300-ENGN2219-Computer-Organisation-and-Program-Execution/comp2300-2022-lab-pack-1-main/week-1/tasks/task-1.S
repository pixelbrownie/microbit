.syntax unified
.global main

.equ GPIO0_BASE,    0x50000000
.equ GPIO0_OUTSET,  0x508
.equ GPIO0_OUTCLR,  0x50C
.equ GPIO0_DIRSET,  0x518
.equ GPIO0_DIRCLR,  0x51C
.equ GPIO0_IN,      0x510
.equ GPIO0_PIN_CNF, 0x700

.equ GPIO1_BASE,    0x50000300
.equ GPIO1_OUTSET,  0x508
.equ GPIO1_OUTCLR,  0x50C
.equ GPIO1_DIRSET,  0x518
.equ GPIO1_PIN_CNF, 0x700

.equ ROW1_BIT,  0x00200000
.equ ROW2_BIT,  0x00400000
.equ ROW3_BIT,  0x00008000
.equ ROW4_BIT,  0x01000000
.equ ROW5_BIT,  0x00080000
.equ COL1_BIT,  0x10000000
.equ COL2_BIT,  0x00000800
.equ COL3_BIT,  0x80000000
.equ COL4_BIT,  0x00000020
.equ COL5_BIT,  0x40000000
.equ ALL_ROWS,  0x01688000
.equ P0_COLS,   0xD0000800
.equ BTNA_BIT,  0x00004000
.equ BTNB_BIT,  0x00800000

@ =============================================================================
@ Digit patterns 0-5, each = 5 bytes, bit4=col1..bit0=col5
@ =============================================================================
.section .rodata
.align 2

d5: .byte 0b11111, 0b10000, 0b11111, 0b00001, 0b11111
d4: .byte 0b10001, 0b10001, 0b11111, 0b00001, 0b00001
d3: .byte 0b11111, 0b00001, 0b11111, 0b00001, 0b11111
d2: .byte 0b11111, 0b00001, 0b11111, 0b10000, 0b11111
d1: .byte 0b00100, 0b01100, 0b00100, 0b00100, 0b11111
d0: .byte 0b11111, 0b10001, 0b10001, 0b10001, 0b11111
ex: .byte 0b00100, 0b01110, 0b11111, 0b01110, 0b00100

dtable:
    .word d0, d1, d2, d3, d4, d5

@ =============================================================================
@ r10 = GPIO0_BASE
@ r11 = GPIO1_BASE
@ r7  = current count (5 down to 0)
@ r6  = pattern pointer
@ r5  = tick counter
@ r4  = paused flag (0=running, 1=paused)
@ =============================================================================
.text
.type main, %function
main:
    ldr r10, =GPIO0_BASE
    ldr r11, =GPIO1_BASE

    @ LED pins output
    ldr r1, =0x00000003
    str r1, [r10, #(GPIO0_PIN_CNF + 21*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 22*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 15*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 24*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 19*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 28*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 11*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 31*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 30*4)]
    str r1, [r11, #(GPIO1_PIN_CNF +  5*4)]

    @ Button pins input with pullup
    ldr r1, =0x0000000C
    str r1, [r10, #(GPIO0_PIN_CNF + 14*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 23*4)]

    @ DIRSET LEDs
    ldr r0, =ALL_ROWS
    ldr r1, =P0_COLS
    orr r0, r0, r1
    str r0, [r10, #GPIO0_DIRSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_DIRSET]

    @ DIRCLR buttons
    ldr r0, =BTNA_BIT
    str r0, [r10, #GPIO0_DIRCLR]
    ldr r0, =BTNB_BIT
    str r0, [r10, #GPIO0_DIRCLR]

    @ All LEDs off
    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTSET]

    mov r7, #5          @ start at 5
    mov r4, #0          @ not paused
    ldr r5, =800        @ tick counter

main_loop:
    @ Load pattern for r7
    ldr r6, =dtable
    lsl r2, r7, #2
    ldr r6, [r6, r2]

    bl display_frame

    @ Check Button A -> reset
    ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNA_BIT
    tst r0, r1
    beq do_reset

    @ Check Button B -> pause/resume
    ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNB_BIT
    tst r0, r1
    beq do_pause

    @ If paused don't tick
    cmp r4, #1
    beq main_loop

    subs r5, r5, #1
    bne main_loop

    ldr r5, =800

    cmp r7, #0
    beq main_loop       @ stay at 0

    subs r7, r7, #1

    cmp r7, #0
    bne main_loop

    @ Hit 0 - flash explosion
    mov r3, #6
explode_loop:
    ldr r6, =ex
    bl display_frame
    bl display_frame
    bl display_frame
    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTSET]
    ldr r2, =50000
eoff: subs r2, r2, #1
    bne eoff
    subs r3, r3, #1
    bne explode_loop
    b main_loop

do_reset:
    mov r7, #5
    ldr r5, =800
    mov r4, #0
rst_w: ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNA_BIT
    tst r0, r1
    beq rst_w
    b main_loop

do_pause:
    eor r4, r4, #1
pse_w: ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNB_BIT
    tst r0, r1
    beq pse_w
    b main_loop

@ =============================================================================
@ display_frame: multiplex all 5 rows of pattern at r6
@ =============================================================================
display_frame:
    push {r0, r1, r2, r3, lr}

    @ ROW1
    ldrb r0, [r6, #0]
    ldr r1, =ALL_ROWS
    str r1, [r10, #GPIO0_OUTCLR]
    ldr r1, =P0_COLS
    str r1, [r10, #GPIO0_OUTSET]
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTSET]
    ldr r1, =ROW1_BIT
    str r1, [r10, #GPIO0_OUTSET]
    tst r0, #0b10000
    beq f1c1
    ldr r1, =COL1_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f1c1: tst r0, #0b01000
    beq f1c2
    ldr r1, =COL2_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f1c2: tst r0, #0b00100
    beq f1c3
    ldr r1, =COL3_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f1c3: tst r0, #0b00010
    beq f1c4
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTCLR]
f1c4: tst r0, #0b00001
    beq f1c5
    ldr r1, =COL5_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f1c5: ldr r3, =3000
dh1:  subs r3, r3, #1
    bne dh1

    @ ROW2
    ldrb r0, [r6, #1]
    ldr r1, =ALL_ROWS
    str r1, [r10, #GPIO0_OUTCLR]
    ldr r1, =P0_COLS
    str r1, [r10, #GPIO0_OUTSET]
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTSET]
    ldr r1, =ROW2_BIT
    str r1, [r10, #GPIO0_OUTSET]
    tst r0, #0b10000
    beq f2c1
    ldr r1, =COL1_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f2c1: tst r0, #0b01000
    beq f2c2
    ldr r1, =COL2_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f2c2: tst r0, #0b00100
    beq f2c3
    ldr r1, =COL3_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f2c3: tst r0, #0b00010
    beq f2c4
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTCLR]
f2c4: tst r0, #0b00001
    beq f2c5
    ldr r1, =COL5_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f2c5: ldr r3, =3000
dh2:  subs r3, r3, #1
    bne dh2

    @ ROW3
    ldrb r0, [r6, #2]
    ldr r1, =ALL_ROWS
    str r1, [r10, #GPIO0_OUTCLR]
    ldr r1, =P0_COLS
    str r1, [r10, #GPIO0_OUTSET]
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTSET]
    ldr r1, =ROW3_BIT
    str r1, [r10, #GPIO0_OUTSET]
    tst r0, #0b10000
    beq f3c1
    ldr r1, =COL1_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f3c1: tst r0, #0b01000
    beq f3c2
    ldr r1, =COL2_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f3c2: tst r0, #0b00100
    beq f3c3
    ldr r1, =COL3_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f3c3: tst r0, #0b00010
    beq f3c4
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTCLR]
f3c4: tst r0, #0b00001
    beq f3c5
    ldr r1, =COL5_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f3c5: ldr r3, =3000
dh3:  subs r3, r3, #1
    bne dh3

    @ ROW4
    ldrb r0, [r6, #3]
    ldr r1, =ALL_ROWS
    str r1, [r10, #GPIO0_OUTCLR]
    ldr r1, =P0_COLS
    str r1, [r10, #GPIO0_OUTSET]
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTSET]
    ldr r1, =ROW4_BIT
    str r1, [r10, #GPIO0_OUTSET]
    tst r0, #0b10000
    beq f4c1
    ldr r1, =COL1_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f4c1: tst r0, #0b01000
    beq f4c2
    ldr r1, =COL2_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f4c2: tst r0, #0b00100
    beq f4c3
    ldr r1, =COL3_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f4c3: tst r0, #0b00010
    beq f4c4
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTCLR]
f4c4: tst r0, #0b00001
    beq f4c5
    ldr r1, =COL5_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f4c5: ldr r3, =3000
dh4:  subs r3, r3, #1
    bne dh4

    @ ROW5
    ldrb r0, [r6, #4]
    ldr r1, =ALL_ROWS
    str r1, [r10, #GPIO0_OUTCLR]
    ldr r1, =P0_COLS
    str r1, [r10, #GPIO0_OUTSET]
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTSET]
    ldr r1, =ROW5_BIT
    str r1, [r10, #GPIO0_OUTSET]
    tst r0, #0b10000
    beq f5c1
    ldr r1, =COL1_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f5c1: tst r0, #0b01000
    beq f5c2
    ldr r1, =COL2_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f5c2: tst r0, #0b00100
    beq f5c3
    ldr r1, =COL3_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f5c3: tst r0, #0b00010
    beq f5c4
    ldr r1, =COL4_BIT
    str r1, [r11, #GPIO1_OUTCLR]
f5c4: tst r0, #0b00001
    beq f5c5
    ldr r1, =COL5_BIT
    str r1, [r10, #GPIO0_OUTCLR]
f5c5: ldr r3, =3000
dh5:  subs r3, r3, #1
    bne dh5

    pop {r0, r1, r2, r3, pc}

.size main, .-main
