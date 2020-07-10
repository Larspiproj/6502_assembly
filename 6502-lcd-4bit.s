PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003
STORE_A = $1000

E  = %10000000
RW = %01000000
RS = %00100000

    .org $8000

reset:
    lda #%11111111      ; Set all pins on port B to output
    sta DDRB

    lda #%11100000      ; Set top 3 pins on port A to output
    sta DDRA
    jsr lcd_init
    ;jsr delay_loop

    ldy #0
print:
    lda message,y
    beq loop
    jsr send_char
    iny
    jmp print

loop:
    jmp loop

;message: .asciiz "Hello, world!"
message: .asciiz "6502-lcd-4bit"

lcd_init:
    ;lda #%00110011     ; Initialize, 0x33
    ;jsr send_byte
    ;lda #%00110000     ; Initialize, 0x30 (3 x 0x30) 
    ;jsr send_byte
    lda #%00000010      ; Set to 4-bit operation, 0x02
    jsr send_byte
    lda #%00101000      ; Function set, 0x28
    jsr send_byte
    lda #%00001110      ; Display on/off control, 0x0e
    jsr send_byte
    lda #%00000110      ; Entry mode set, 0x06
    jsr send_byte
    lda #%00000001      ; Clear display, 0x01
    jsr send_byte
    jsr delay_loop
    rts

delay_loop:
    ldy #$03            ; Two nested loops delay 1.4 ms
    ldx #$02            ; Inner loop >= outer loop
loop1:
    dey
    bne loop1
    dex
    bne loop1
    rts

send_byte:
    sta STORE_A
    jsr send_nibble
    jsr lcd_instruction
    jsr shift_left
    jsr send_nibble
    jsr lcd_instruction
    rts

send_char:
    sta STORE_A
    jsr send_nibble
    jsr print_char
    jsr shift_left
    jsr send_nibble
    jsr print_char
    rts

send_nibble:
    and #$f0
    sta PORTB
    rts

lcd_instruction:
    jsr lcd_wait
    lda #0              ; Sets RS/RW/E bits
    sta PORTA
    lda #E              ; Toggle E bit 
    sta PORTA
    lda #0              ; Sets RS/RW/E bits
    sta PORTA
    rts

print_char:
    jsr lcd_wait
    lda #RS          ; Sets RS/RW/E bits
    sta PORTA
    lda #(RS | E)    ; Toggle E bit 
    sta PORTA
    lda #RS          ; Sets RS/RW/E bits
    sta PORTA
    rts

lcd_wait:
    pha
    lda #%00000000      ;   Port B is input
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
    lda #%11111111      ;   Port B is output again
    sta DDRB
    pla
    rts
    
shift_left:
    ldx #$04
    lda STORE_A
decrement:
    dex
    asl
    cpx #$0
    bne decrement       ; Branch if Z = 0
    rts

    .org $fffc
    .word reset
    .word $0000
