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

@ Speaker = P0.00
.equ SPEAKER_BIT, 0x00000001

@ TWIM0
.equ TWIM0_BASE,          0x40003000
.equ TWIM_TASKS_STARTTX,  0x008
.equ TWIM_EVENTS_STOPPED, 0x104
.equ TWIM_EVENTS_ERROR,   0x124
.equ TWIM_EVENTS_LASTTX,  0x160
.equ TWIM_EVENTS_LASTRX,  0x15C
.equ TWIM_SHORTS,         0x200
.equ TWIM_INTENCLR,       0x308
.equ TWIM_ENABLE,         0x500
.equ TWIM_PSEL_SCL,       0x508
.equ TWIM_PSEL_SDA,       0x50C
.equ TWIM_FREQUENCY,      0x524
.equ TWIM_RXD_PTR,        0x534
.equ TWIM_RXD_MAXCNT,     0x538
.equ TWIM_TXD_PTR,        0x544
.equ TWIM_TXD_MAXCNT,     0x548
.equ TWIM_ADDRESS,        0x588
.equ TWIM_FREQ_100K,      0x01980000

.equ ACC_ADDR,    0x19
.equ CTRL_REG1_A, 0x20
.equ OUT_X_H_A,   0x29

.equ PIN_CNF_OUT, 0x00000003
.equ PIN_CNF_I2C, 0x0000060C

@ =============================================================================
@ Lookup tables
@ =============================================================================
.section .rodata
.align 2
row_table:
    .word 0x00200000
    .word 0x00400000
    .word 0x00008000
    .word 0x01000000
    .word 0x00080000

col_table:
    .word 0x10000000    @ COL1 P0
    .word 0x00000800    @ COL2 P0
    .word 0x80000000    @ COL3 P0
    .word 0x00000020    @ COL4 P1
    .word 0x40000000    @ COL5 P0

col_p1:
    .byte 0, 0, 0, 1, 0

@ =============================================================================
@ Game state in RAM
@ =============================================================================
.data
.align 2
tx_buf:     .byte 0, 0
rx_buf:     .byte 0
ball_col:   .word 2         @ ball column (0-4)
ball_row:   .word 0         @ ball row (0-4), starts at top
basket_col: .word 2         @ basket center col (0-4)
score:      .word 0         @ number of catches
lives:      .word 3         @ lives remaining
speed:      .word 600       @ fall speed (tick frames, decreases as score increases)

@ =============================================================================
@ r10 = GPIO0_BASE
@ r11 = GPIO1_BASE
@ r8  = TWIM0_BASE
@ =============================================================================
.text
.type main, %function
main:
    ldr r10, =GPIO0_BASE
    ldr r11, =GPIO1_BASE
    ldr r8,  =TWIM0_BASE

    @ LED pins output
    ldr r1, =PIN_CNF_OUT
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

    @ Speaker pin output
    str r1, [r10, #(GPIO0_PIN_CNF + 0*4)]
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_DIRSET]

    @ Button pins input with pullup
    ldr r1, =0x0000000C
    str r1, [r10, #(GPIO0_PIN_CNF + 14*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 23*4)]

    @ I2C pins
    ldr r1, =PIN_CNF_I2C
    str r1, [r10, #(GPIO0_PIN_CNF + 8*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 16*4)]

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

    @ Setup TWIM0
    mov r0, #0
    str r0, [r8, #TWIM_ENABLE]
    mov r0, #8
    str r0, [r8, #TWIM_PSEL_SCL]
    mov r0, #16
    str r0, [r8, #TWIM_PSEL_SDA]
    ldr r0, =TWIM_FREQ_100K
    str r0, [r8, #TWIM_FREQUENCY]
    mov r0, #ACC_ADDR
    str r0, [r8, #TWIM_ADDRESS]
    ldr r0, =0xFFFFFFFF
    str r0, [r8, #TWIM_INTENCLR]
    mov r0, #6
    str r0, [r8, #TWIM_ENABLE]

    ldr r3, =200000
isl: subs r3, r3, #1
    bne isl

    @ Init accelerometer: 100Hz all axes
    ldr r0, =tx_buf
    mov r1, #CTRL_REG1_A
    strb r1, [r0, #0]
    mov r1, #0x57
    strb r1, [r0, #1]
    str r0, [r8, #TWIM_TXD_PTR]
    mov r1, #2
    str r1, [r8, #TWIM_TXD_MAXCNT]
    mov r0, #0x200
    str r0, [r8, #TWIM_SHORTS]
    mov r0, #0
    str r0, [r8, #TWIM_EVENTS_STOPPED]
    str r0, [r8, #TWIM_EVENTS_LASTTX]
    mov r0, #1
    str r0, [r8, #TWIM_TASKS_STARTTX]
wi: ldr r0, [r8, #TWIM_EVENTS_STOPPED]
    cmp r0, #0
    beq wi

    ldr r3, =50000
idl: subs r3, r3, #1
    bne idl

    @ Play startup tune
    bl play_happy

@ =============================================================================
@ GAME LOOP
@ r5 = tick counter (counts down, when 0 drop ball one row)
@ =============================================================================
game_loop:
    ldr r5, =speed
    ldr r5, [r5]

tick_loop:
    @ Read accelerometer -> update basket
    mov r0, #OUT_X_H_A
    bl twim_read_byte
    sxtb r4, r0

    @ Map X to basket col: clamp((X>>5)+2, 0, 4)
    @ Use larger divisor (>>4 instead of >>5) for less sensitivity at corners
    asr r0, r4, #4
    add r0, r0, #2
    cmp r0, #0
    it lt
    movlt r0, #0
    cmp r0, #4
    it gt
    movgt r0, #4
    ldr r1, =basket_col
    str r0, [r1]

    @ Draw frame
    bl draw_frame

    @ Button B = speed up
    ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNB_BIT
    tst r0, r1
    beq do_speedup

    subs r5, r5, #1
    bne tick_loop
    b after_tick

do_speedup:
    ldr r0, =speed
    ldr r1, [r0]
    subs r1, r1, #50
    ldr r2, =150
    cmp r1, r2
    it lt
    movlt r1, r2
    str r1, [r0]
    @ wait release
spd_wait:
    ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNB_BIT
    tst r0, r1
    beq spd_wait
    b tick_loop

after_tick:

    @ --- Drop ball one row ---
    ldr r0, =ball_row
    ldr r1, [r0]
    add r1, r1, #1

    @ Check if ball reached bottom (row 4)
    cmp r1, #4
    blt ball_still_falling
    beq ball_at_bottom

ball_still_falling:
    str r1, [r0]
    b game_loop

ball_at_bottom:
    str r1, [r0]

    @ Check if basket catches ball
    @ basket spans col-1, col, col+1 (3 wide, clamped)
    ldr r2, =basket_col
    ldr r2, [r2]
    ldr r3, =ball_col
    ldr r3, [r3]

    @ caught if |basket_col - ball_col| <= 1
    subs r0, r2, r3
    it lt
    neglt r0, r0            @ abs difference
    cmp r0, #1
    ble caught
    b missed

caught:
    @ Increment score
    ldr r0, =score
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    @ Speed up: reduce speed by 30, min 200
    ldr r0, =speed
    ldr r1, [r0]
    subs r1, r1, #30
    ldr r2, =200
    cmp r1, r2
    it lt
    movlt r1, r2
    str r1, [r0]

    @ Happy sound
    bl play_happy

    @ Reset ball to random-ish col based on basket_col XOR score
    ldr r0, =score
    ldr r0, [r0]
    ldr r1, =basket_col
    ldr r1, [r1]
    eor r0, r0, r1
    and r0, r0, #0x3        @ 0-3
    ldr r1, =ball_col
    str r0, [r1]
    ldr r1, =ball_row
    mov r0, #0
    str r0, [r1]
    b game_loop

missed:
    @ Lose a life
    ldr r0, =lives
    ldr r1, [r0]
    subs r1, r1, #1
    str r1, [r0]

    @ Sad sound
    bl play_sad

    @ Game over if 0 lives
    cmp r1, #0
    beq game_over

    @ Reset ball
    ldr r0, =ball_col
    mov r1, #2
    str r1, [r0]
    ldr r0, =ball_row
    mov r1, #0
    str r1, [r0]
    b game_loop

game_over:
    @ Flash all LEDs 5 times
    mov r3, #5
go_flash:
    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTCLR]
    ldr r2, =300000
go_on: subs r2, r2, #1
    bne go_on
    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTSET]
    ldr r2, =300000
go_off: subs r2, r2, #1
    bne go_off
    subs r3, r3, #1
    bne go_flash

    @ Wait for Button A to restart
    bl play_sad
restart_wait:
    ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNA_BIT
    tst r0, r1
    bne restart_wait

    @ Reset game state
    ldr r0, =ball_col
    mov r1, #2
    str r1, [r0]
    ldr r0, =ball_row
    mov r1, #0
    str r1, [r0]
    ldr r0, =basket_col
    mov r1, #2
    str r1, [r0]
    ldr r0, =score
    mov r1, #0
    str r1, [r0]
    ldr r0, =lives
    mov r1, #3
    str r1, [r0]
    ldr r0, =speed
    ldr r1, =600
    str r1, [r0]

    bl play_happy
    b game_loop

@ =============================================================================
@ draw_frame: draw ball + basket + score indicator
@ Ball = single LED at (ball_row, ball_col)
@ Basket = 3 LEDs on row4 centered at basket_col
@ Score = lives shown as lit LEDs on col0, rows from bottom
@ =============================================================================
draw_frame:
    push {r0, r1, r2, r3, r4, r5, lr}

    @ All off
    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTSET]

    @ Draw ball
    ldr r4, =ball_row
    ldr r4, [r4]
    ldr r5, =ball_col
    ldr r5, [r5]
    bl light_one_led

    @ Draw basket: 3 LEDs on row 4 centered at basket_col
    ldr r5, =basket_col
    ldr r5, [r5]
    mov r4, #4              @ row 4 = bottom

    @ center
    bl light_one_led

    @ left (basket_col - 1, clamped)
    subs r5, r5, #1
    it lt
    movlt r5, #0
    ldr r0, =basket_col
    ldr r0, [r0]
    cmp r5, r0              @ don't draw if same as center (already drawn)
    bne df_left_ok
    b df_right
df_left_ok:
    bl light_one_led

df_right:
    @ right (basket_col + 1, clamped)
    ldr r5, =basket_col
    ldr r5, [r5]
    add r5, r5, #1
    cmp r5, #4
    it gt
    movgt r5, #4
    ldr r0, =basket_col
    ldr r0, [r0]
    cmp r5, r0
    bne df_right_ok
    b df_score
df_right_ok:
    bl light_one_led

df_score:
    @ Show lives as lit LEDs on leftmost col (col 0), from bottom
    @ 3 lives = row4,row3,row2 lit on col0
    ldr r5, =lives
    ldr r5, [r5]
    mov r4, #4              @ start from bottom row
    mov r0, #0              @ col 0
    push {r5}
lives_loop:
    cmp r5, #0
    beq lives_done
    @ light (r4, col0) if not occupied by basket on row4
    mov r5, r4
    ldr r1, =basket_col
    ldr r1, [r1]
    @ skip if row4 and col0 conflicts with basket (col0 < basket-1 so usually fine)
    push {r0}
    mov r4, r5
    mov r5, #0              @ col 0
    bl light_one_led
    pop {r0}
    mov r5, r4
    subs r4, r4, #1
    ldr r1, [sp]
    sub r1, r1, #1
    str r1, [sp]
    ldr r5, [sp]
    b lives_loop
lives_done:
    pop {r5}

    pop {r0, r1, r2, r3, r4, r5, pc}

@ =============================================================================
@ light_one_led: light LED at row=r4, col=r5 briefly
@ Preserves all registers except r0,r1,r2,r3
@ =============================================================================
light_one_led:
    push {r0, r1, r2, r3, lr}

    @ Set row
    ldr r0, =row_table
    lsl r2, r4, #2
    ldr r1, [r0, r2]
    str r1, [r10, #GPIO0_OUTSET]

    @ Set col
    ldr r0, =col_table
    lsl r2, r5, #2
    ldr r1, [r0, r2]
    ldr r0, =col_p1
    ldrb r2, [r0, r5]
    cmp r2, #1
    beq lol_p1
    str r1, [r10, #GPIO0_OUTCLR]
    b lol_done
lol_p1:
    str r1, [r11, #GPIO1_OUTCLR]
lol_done:
    ldr r3, =2000
lh: subs r3, r3, #1
    bne lh

    @ Turn this LED off (leave rows/cols state for next call)
    ldr r0, =row_table
    lsl r2, r4, #2
    ldr r1, [r0, r2]
    str r1, [r10, #GPIO0_OUTCLR]

    ldr r0, =col_table
    lsl r2, r5, #2
    ldr r1, [r0, r2]
    ldr r0, =col_p1
    ldrb r2, [r0, r5]
    cmp r2, #1
    beq lol2_p1
    str r1, [r10, #GPIO0_OUTSET]
    b lol2_done
lol2_p1:
    str r1, [r11, #GPIO1_OUTSET]
lol2_done:
    pop {r0, r1, r2, r3, pc}

@ =============================================================================
@ play_happy: cheerful YAY melody C-E-G-high-C ascending
@ =============================================================================
play_happy:
    push {r0, r1, r2, r3, lr}

    @ Note C4 ~262Hz: half-period = 64MHz/(262*2) ~ 1908 cycles
    mov r2, #80
ph_c4:
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_OUTSET]
    ldr r3, =1908
ph_c4h: subs r3, r3, #1
    bne ph_c4h
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r3, =1908
ph_c4l: subs r3, r3, #1
    bne ph_c4l
    subs r2, r2, #1
    bne ph_c4

    @ Note E4 ~330Hz: half-period ~ 1515
    mov r2, #80
ph_e4:
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_OUTSET]
    ldr r3, =1515
ph_e4h: subs r3, r3, #1
    bne ph_e4h
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r3, =1515
ph_e4l: subs r3, r3, #1
    bne ph_e4l
    subs r2, r2, #1
    bne ph_e4

    @ Note G4 ~392Hz: half-period ~ 1276
    mov r2, #80
ph_g4:
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_OUTSET]
    ldr r3, =1276
ph_g4h: subs r3, r3, #1
    bne ph_g4h
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r3, =1276
ph_g4l: subs r3, r3, #1
    bne ph_g4l
    subs r2, r2, #1
    bne ph_g4

    @ Note C5 ~523Hz: half-period ~ 954
    mov r2, #120
ph_c5:
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_OUTSET]
    ldr r3, =954
ph_c5h: subs r3, r3, #1
    bne ph_c5h
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r3, =954
ph_c5l: subs r3, r3, #1
    bne ph_c5l
    subs r2, r2, #1
    bne ph_c5

    pop {r0, r1, r2, r3, pc}

@ =============================================================================
@ play_sad: droopy AWW melody G-E-C descending slow
@ =============================================================================
play_sad:
    push {r0, r1, r2, r3, lr}

    @ Note G4 ~392Hz
    mov r2, #100
ps_g4:
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_OUTSET]
    ldr r3, =1276
ps_g4h: subs r3, r3, #1
    bne ps_g4h
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r3, =1276
ps_g4l: subs r3, r3, #1
    bne ps_g4l
    subs r2, r2, #1
    bne ps_g4

    @ Note E4 ~330Hz
    mov r2, #100
ps_e4:
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_OUTSET]
    ldr r3, =1515
ps_e4h: subs r3, r3, #1
    bne ps_e4h
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r3, =1515
ps_e4l: subs r3, r3, #1
    bne ps_e4l
    subs r2, r2, #1
    bne ps_e4

    @ Note C4 ~262Hz (long and droopy)
    mov r2, #180
ps_c4:
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_OUTSET]
    ldr r3, =1908
ps_c4h: subs r3, r3, #1
    bne ps_c4h
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r3, =1908
ps_c4l: subs r3, r3, #1
    bne ps_c4l
    subs r2, r2, #1
    bne ps_c4

    pop {r0, r1, r2, r3, pc}

@ =============================================================================
@ twim_read_byte: r0=reg -> r0=byte
@ =============================================================================
twim_read_byte:
    push {r1, r2, r3, lr}

    ldr r2, =tx_buf
    strb r0, [r2, #0]
    str r2, [r8, #TWIM_TXD_PTR]
    mov r1, #1
    str r1, [r8, #TWIM_TXD_MAXCNT]
    ldr r2, =rx_buf
    str r2, [r8, #TWIM_RXD_PTR]
    mov r1, #1
    str r1, [r8, #TWIM_RXD_MAXCNT]
    ldr r1, =0x1080
    str r1, [r8, #TWIM_SHORTS]
    mov r1, #0
    str r1, [r8, #TWIM_EVENTS_STOPPED]
    str r1, [r8, #TWIM_EVENTS_ERROR]
    str r1, [r8, #TWIM_EVENTS_LASTTX]
    str r1, [r8, #TWIM_EVENTS_LASTRX]
    mov r1, #1
    str r1, [r8, #TWIM_TASKS_STARTTX]
trb: ldr r1, [r8, #TWIM_EVENTS_STOPPED]
    cmp r1, #0
    beq trb
    ldr r2, =rx_buf
    ldrb r0, [r2, #0]

    pop {r1, r2, r3, pc}

.size main, .-main