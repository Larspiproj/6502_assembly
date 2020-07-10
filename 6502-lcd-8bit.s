PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003

E  = %10000000
RW = %01000000
RS = %00100000

    .org $8000

reset:
    lda #%11111111  ; Set all pins on port B to output
    sta DDRB

    lda #%11100000  ; Set top 3 pins on port A to output
    sta DDRA
    jsr lcd_init

    ldx #0
print:
    lda message,x
    beq loop
    jsr print_char
    inx
    jmp print

loop:
    jmp loop

message: .asciiz "6502-lcd-8bit"

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
