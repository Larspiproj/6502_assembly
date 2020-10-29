  .org $0000
  .word $0000

  .org $0010

reset:
  lda #$ff
  sta $6002

loop:
  lda #$55
  sta $6000

  lda #$aa
  sta $6000

  jmp loop

  .org $1ffc
  .word reset
  .word $0000
