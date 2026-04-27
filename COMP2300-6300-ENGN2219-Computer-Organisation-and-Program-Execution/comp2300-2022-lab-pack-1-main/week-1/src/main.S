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

.equ SPEAKER_BIT, 0x00000001

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
    .word 0x10000000
    .word 0x00000800
    .word 0x80000000
    .word 0x00000020
    .word 0x40000000

col_p1:
    .byte 0, 0, 0, 1, 0

@ =============================================================================
@ Game state
@ =============================================================================
.data
.align 2
tx_buf:      .byte 0, 0
rx_buf:      .byte 0
             .align 2
ball_col:    .word 2
ball_row:    .word 0
basket_col:  .word 2
score:       .word 0
lives:       .word 3
speed:       .word 600
basket_size: .word 3
last_btnb:   .word 0

@ =============================================================================
@ r10 = GPIO0_BASE  r11 = GPIO1_BASE  r8 = TWIM0_BASE
@ =============================================================================
.text
.type main, %function
main:
    ldr r10, =GPIO0_BASE
    ldr r11, =GPIO1_BASE
    ldr r8,  =TWIM0_BASE

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

    str r1, [r10, #(GPIO0_PIN_CNF + 0*4)]
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_DIRSET]

    ldr r1, =0x0000000C
    str r1, [r10, #(GPIO0_PIN_CNF + 14*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 23*4)]

    ldr r1, =PIN_CNF_I2C
    str r1, [r10, #(GPIO0_PIN_CNF + 8*4)]
    str r1, [r10, #(GPIO0_PIN_CNF + 16*4)]

    ldr r0, =ALL_ROWS
    ldr r1, =P0_COLS
    orr r0, r0, r1
    str r0, [r10, #GPIO0_DIRSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_DIRSET]

    ldr r0, =BTNA_BIT
    str r0, [r10, #GPIO0_DIRCLR]
    ldr r0, =BTNB_BIT
    str r0, [r10, #GPIO0_DIRCLR]

    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTSET]

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

    bl play_happy

@ =============================================================================
@ GAME LOOP
@ =============================================================================
game_loop:
    ldr r5, =speed
    ldr r5, [r5]

tick_loop:
    @ Read X axis -> basket column
    mov r0, #OUT_X_H_A
    bl twim_read_byte
    sxtb r4, r0
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

    bl draw_frame

    @ Increment double-tap timer
    ldr r0, =last_btnb
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    @ Button B? (active-low)
    ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNB_BIT
    tst r0, r1
    beq do_btnb

    subs r5, r5, #1
    bne tick_loop
    b after_tick

do_btnb:
    ldr r0, =last_btnb
    ldr r1, [r0]
    cmp r1, #80
    blt do_shrink_basket

    @ Single tap: speed up (min 150)
    ldr r0, =speed
    ldr r1, [r0]
    subs r1, r1, #50
    ldr r2, =150
    cmp r1, r2
    it lt
    movlt r1, r2
    str r1, [r0]
    b btnb_done

do_shrink_basket:
    @ Double tap: cycle basket size 3->2->1->3
    ldr r0, =basket_size
    ldr r1, [r0]
    subs r1, r1, #1
    cmp r1, #0
    it eq
    moveq r1, #3
    str r1, [r0]
    bl play_click

btnb_done:
    ldr r0, =last_btnb
    mov r1, #0
    str r1, [r0]
btnb_wait:
    ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNB_BIT
    tst r0, r1
    beq btnb_wait
    b tick_loop

after_tick:
    ldr r0, =ball_row
    ldr r1, [r0]
    add r1, r1, #1
    cmp r1, #4
    blt ball_still_falling
    beq ball_at_bottom

ball_still_falling:
    str r1, [r0]
    b game_loop

ball_at_bottom:
    str r1, [r0]

    ldr r2, =basket_col
    ldr r2, [r2]
    ldr r3, =ball_col
    ldr r3, [r3]
    subs r0, r2, r3
    it lt
    neglt r0, r0
    ldr r1, =basket_size
    ldr r1, [r1]
    cmp r1, #3
    beq catch_wide
    cmp r1, #2
    beq catch_mid
    cmp r0, #0
    beq caught
    b missed
catch_mid:
    cmp r0, #1
    ble caught
    b missed
catch_wide:
    cmp r0, #1
    ble caught
    b missed

caught:
    ldr r0, =score
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    @ Speed up on catch: -30, min 200
    ldr r0, =speed
    ldr r1, [r0]
    subs r1, r1, #30
    ldr r2, =200
    cmp r1, r2
    it lt
    movlt r1, r2
    str r1, [r0]

    bl play_happy

    @ Pseudo-random next column
    ldr r0, =score
    ldr r0, [r0]
    ldr r1, =basket_col
    ldr r1, [r1]
    eor r0, r0, r1
    and r0, r0, #0x3
    ldr r1, =ball_col
    str r0, [r1]
    ldr r1, =ball_row
    mov r0, #0
    str r0, [r1]
    b game_loop

missed:
    ldr r0, =lives
    ldr r1, [r0]
    subs r1, r1, #1
    str r1, [r0]
    bl play_sad
    cmp r1, #0
    beq game_over
    ldr r0, =ball_col
    mov r1, #2
    str r1, [r0]
    ldr r0, =ball_row
    mov r1, #0
    str r1, [r0]
    b game_loop

@ =============================================================================
@ GAME OVER: flash all LEDs 5 times, then wait for Button A
@ =============================================================================
game_over:
    mov r3, #5
go_flash:
    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTCLR]
    ldr r2, =300000
go_on:  subs r2, r2, #1
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

    bl play_sad

restart_wait:
    ldr r0, [r10, #GPIO0_IN]
    ldr r1, =BTNA_BIT
    tst r0, r1
    bne restart_wait

    @ Reset state
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
    ldr r0, =basket_size
    mov r1, #3
    str r1, [r0]
    ldr r0, =last_btnb
    mov r1, #0
    str r1, [r0]

    bl play_happy
    b game_loop

@ =============================================================================
@ draw_frame
@ =============================================================================
draw_frame:
    push {r0, r1, r2, r3, r4, r5, lr}

    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTSET]

    @ Ball
    ldr r4, =ball_row
    ldr r4, [r4]
    ldr r5, =ball_col
    ldr r5, [r5]
    bl light_one_led

    @ Basket center
    ldr r5, =basket_col
    ldr r5, [r5]
    mov r4, #4
    bl light_one_led

    ldr r0, =basket_size
    ldr r0, [r0]
    cmp r0, #1
    beq df_lives

    @ Left wing
    ldr r5, =basket_col
    ldr r5, [r5]
    subs r5, r5, #1
    it lt
    movlt r5, #0
    ldr r0, =basket_col
    ldr r0, [r0]
    cmp r5, r0
    beq df_right
    mov r4, #4
    bl light_one_led

df_right:
    ldr r5, =basket_col
    ldr r5, [r5]
    add r5, r5, #1
    cmp r5, #4
    it gt
    movgt r5, #4
    ldr r0, =basket_col
    ldr r0, [r0]
    cmp r5, r0
    beq df_lives
    mov r4, #4
    bl light_one_led

df_lives:
    bl draw_lives_digit

    pop {r0, r1, r2, r3, r4, r5, pc}

@ =============================================================================
@ light_one_led: row=r4, col=r5
@ =============================================================================
light_one_led:
    push {r0, r1, r2, r3, lr}

    ldr r0, =row_table
    lsl r2, r4, #2
    ldr r1, [r0, r2]
    str r1, [r10, #GPIO0_OUTSET]

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
@ draw_lives_digit
@ 3 lives: (0,4) + (1,4) + (0,3)
@ 2 lives: (0,4) + (1,4)
@ 1 life:  (0,4) only
@ =============================================================================
draw_lives_digit:
    push {r0, r1, r2, r3, r4, r5, lr}

    ldr r0, =lives
    ldr r0, [r0]

    mov r4, #0
    mov r5, #4
    bl light_one_led

    cmp r0, #1
    beq dl_done

    mov r4, #1
    mov r5, #4
    bl light_one_led

    cmp r0, #2
    beq dl_done

    mov r4, #0
    mov r5, #3
    bl light_one_led

dl_done:
    pop {r0, r1, r2, r3, r4, r5, pc}

@ =============================================================================
@ play_happy: C4-E4-G4-C5
@ =============================================================================
play_happy:
    push {r0, r1, r2, r3, lr}
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
@ play_sad: G4-E4-C4
@ =============================================================================
play_sad:
    push {r0, r1, r2, r3, lr}
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
@ play_click
@ =============================================================================
play_click:
    push {r0, r1, r2, r3, lr}
    mov r2, #30
pc_loop:
    ldr r0, =SPEAKER_BIT
    str r0, [r10, #GPIO0_OUTSET]
    ldr r3, =600
pc_h: subs r3, r3, #1
    bne pc_h
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r3, =600
pc_l: subs r3, r3, #1
    bne pc_l
    subs r2, r2, #1
    bne pc_loop
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