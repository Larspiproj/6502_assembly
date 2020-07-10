PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003

value = $0200 ; Two bytes
mod10 = $0202 ; Two bytes
message = $0204 ; 6 bytes

E  = %10000000
RW = %01000000
RS = %00100000

    .org $8000

reset:
    ldx #$ff
    txs

    lda #%11111111  ; Set all pins on port B to output
    sta DDRB

    lda #%11100000  ; Set top 3 pins on port A to output
    sta DDRA
    jsr lcd_init

    ; Initialize `message`
    lda #0
    sta message

    ; Initialize value to be the number to convert and store value in RAM
    lda number	
    sta value
    lda number +1
    sta value + 1

divide:
    ; Initialize the remainder to zero
    lda #0
    sta mod10
    sta mod10 + 1
    clc

    ldx #16
divloop:
    ; Rotate quatient and remainder
    rol value
    rol value + 1
    rol mod10
    rol mod10 + 1

    ; a,y = dividend - divisor
    sec
    lda mod10
    sbc #10
    tay ; Save low byte in Y
    lda mod10 + 1
    sbc #0
    bcc ignore_result ; Branch if dividend < divisor
    sty mod10
    sta mod10 + 1

ignore_result:
    dex
    bne divloop
    rol value ; Shift in the last bit of the quotient
    rol value + 1

    lda mod10
    clc
    adc #"0"
    jsr push_char

    ; If value != 0, then continue dividing
    lda value
    ora value + 1
    bne divide

    ldx #0
print:
     lda message,x
     beq loop
     jsr print_char
     inx
     jmp print

loop:
    jmp loop

number: .word 1729 ; Store in ROM

; Add the character in the A register to the beginning of the
; null-terminated string `message`
push_char:
    pha ; Push new first char onto stack
    ldy #0
char_loop:
    lda message,y ; Get char on string and move to X
    tax
    pla
    sta message,y ; Pull char off stack and add it to the string
    iny
    txa
    pha		  ; Push char from string onto stack
    bne char_loop
    pla
    sta message,y ; Pull the null off the stack and add to the end of the string
    rts

lcd_init:
    lda #%00111000  ; Set 8-bit mode; 2-line display; 5x8 font
    jsr lcd_instruction
    lda #%00001110  ; Turns on display and cursor; blink off
    jsr lcd_instruction
    lda #%00000110  ; Increment and shift cursor; don't shift display
    jsr lcd_instruction
    lda #%00000001  ; Clear display
    jsr lcd_instruction
    jsr delay_loop
    rts

delay_loop:
    ldy #$03
    ldx #$02
loop1:
    dey
    bne loop1
    dex
    bne loop1
    rts

lcd_wait:
    pha
    lda #%00000000  ;   Port B is input
    sta DDRB
lcd_busy:
    lda #RW
    sta PORTA
    lda #(RW | E)
    sta PORTA
    lda PORTB
    and #%10000000
    bne lcd_busy

    lda #RW
    sta PORTA
    lda #%11111111  ;   Port B is output again
    sta DDRB
    pla
    rts

lcd_instruction:
    jsr lcd_wait
    sta PORTB
    lda #0          ; Clear RS/RW/E bits
    sta PORTA
    lda #E          ; Toggle E bit 
    sta PORTA
    lda #0          ; Clear RS/RW/E bits
    sta PORTA
    rts

print_char:
    jsr lcd_wait
    sta PORTB
    lda #RS          ; Sets RS/RW/E bits
    sta PORTA
    lda #(RS | E)    ; Toggle E bit 
    sta PORTA
    lda #RS          ; Sets RS/RW/E bits
    sta PORTA
    rts

    .org $fffc
    .word reset
    .word $0000
