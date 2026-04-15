.syntax unified
.global main

.equ GPIO0_BASE,    0x50000000
.equ GPIO0_OUTSET,  0x508
.equ GPIO0_OUTCLR,  0x50C
.equ GPIO0_DIRSET,  0x518
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
.equ OUT_Y_H_A,   0x2B

.equ PIN_CNF_OUT, 0x00000003
.equ PIN_CNF_I2C, 0x0000060C

@ =============================================================================
@ Row and col lookup tables
@ col_p1: 0=P0, 1=P1 per column index
@ =============================================================================
.section .rodata
.align 2
row_table:
    .word 0x00200000    @ ROW1
    .word 0x00400000    @ ROW2
    .word 0x00008000    @ ROW3
    .word 0x01000000    @ ROW4
    .word 0x00080000    @ ROW5

col_table:
    .word 0x10000000    @ COL1 P0
    .word 0x00000800    @ COL2 P0
    .word 0x80000000    @ COL3 P0
    .word 0x00000020    @ COL4 P1
    .word 0x40000000    @ COL5 P0

col_p1:
    .byte 0, 0, 0, 1, 0

.data
.align 2
tx_buf: .byte 0, 0
rx_buf: .byte 0

@ =============================================================================
@ r10 = GPIO0_BASE
@ r11 = GPIO1_BASE
@ r8  = TWIM0_BASE
@ r6  = current col (0-4)
@ r7  = current row (0-4)
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

    @ I2C pins: open-drain + pullup
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

    @ Settle delay
    ldr r3, =200000
isl: subs r3, r3, #1
    bne isl

    @ Init accelerometer
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

    @ Start dot at center (row=2, col=2)
    mov r6, #2
    mov r7, #2

    @ Flash center LED 3 times as startup animation
    mov r3, #3
flash_loop:
    bl light_dot
    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTSET]
    ldr r2, =200000
foff: subs r2, r2, #1
    bne foff
    subs r3, r3, #1
    bne flash_loop

@ =============================================================================
@ MAIN LOOP: read accel, move dot
@ =============================================================================
main_loop:
    @ Read X high byte -> col
    mov r0, #OUT_X_H_A
    bl twim_read_byte
    sxtb r4, r0

    @ Read Y high byte -> row
    mov r0, #OUT_Y_H_A
    bl twim_read_byte
    sxtb r5, r0

    @ Map X to col: col = clamp((X >> 5) + 2, 0, 4)
    asr r0, r4, #5
    add r6, r0, #2
    cmp r6, #0
    it lt
    movlt r6, #0
    cmp r6, #4
    it gt
    movgt r6, #4

    @ Map Y to row (invert): row = clamp((-Y >> 5) + 2, 0, 4)
    neg r5, r5
    asr r0, r5, #5
    add r7, r0, #2
    cmp r7, #0
    it lt
    movlt r7, #0
    cmp r7, #4
    it gt
    movgt r7, #4

    @ Light the dot
    bl light_dot

    b main_loop

@ =============================================================================
@ light_dot: light single LED at row=r7, col=r6, hold briefly
@ Preserves r4,r5,r6,r7,r8,r10,r11
@ =============================================================================
light_dot:
    push {r0, r1, r2, r3, lr}

    @ All off
    ldr r0, =ALL_ROWS
    str r0, [r10, #GPIO0_OUTCLR]
    ldr r0, =P0_COLS
    str r0, [r10, #GPIO0_OUTSET]
    ldr r0, =COL4_BIT
    str r0, [r11, #GPIO1_OUTSET]

    @ Set row
    ldr r0, =row_table
    lsl r2, r7, #2
    ldr r1, [r0, r2]
    str r1, [r10, #GPIO0_OUTSET]

    @ Set col
    ldr r0, =col_table
    lsl r2, r6, #2
    ldr r1, [r0, r2]

    @ Check if P1 using flags
    ldr r0, =col_p1
    ldrb r2, [r0, r6]
    cmp r2, #1
    beq ld_p1
    str r1, [r10, #GPIO0_OUTCLR]
    b ld_done
ld_p1:
    str r1, [r11, #GPIO1_OUTCLR]
ld_done:
    ldr r3, =5000
ldh: subs r3, r3, #1
    bne ldh

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