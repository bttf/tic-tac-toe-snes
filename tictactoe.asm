; This dude says, and I quote:
; "This is my standard "Empty Code". If you’d like to test it, add these lines just after InitSNES:
; sep #$30        ; get 8-bit registers
; stz $2121       ; write to CGRAM from $0
; lda #%11101111  ; this is
; ldx #%00111111  ; a green color
; sta $2122       ; write it
; stx $2122       ; to CGRAM
; lda #%00001111  ; turn on screen
; sta $2100       ; here"

.include "header.inc"
.include "initsnes.asm"

.bank 0 slot 0
.org 0
.section "Vblank"
;--------------------------------------
VBlank:
rti	;return from interrupt
;--------------------------------------
.ends


.bank 0 slot 0
.org 0
.section "Main"
;--------------------------------------
Start:
  ;InitSNES
  Snes_Init

  ; this loads the palette
  rep #%00010000  ; 16 bit xy
  sep #%00100000  ; 8 bit ab

  ; taking every byte of the palette and putting it into CGRAM
  ldx #$0000
  _loop1: 
    lda UntitledPalette.l,x 	;UntitledPalette set in 'tiles.inc' which is included at the end of this file; "TilesData" section
    sta $2122
    inx
    cpx #8
    bne _loop1

  ; step 1 cont.
  ;
  ; dude says "I'll explain this later" i ask, when?
  ; "we'll have two palettes, only one color is needed for the second"
  lda #33  ; "the color we need is the 33rd'
  sta $2121
  lda.l Palette2
  sta $2122
  lda.l Palette2+1
  sta $2122

  ; "here goes a typical DMA transfer"
  ldx #UntitledData 	; Address
  lda #:UntitledData	; of UntitledData
  ldy #(15*16*2)	; length of data
  stx $4302		; write
  sta $4304		; address
  sty $4305		; and length
  lda #%00000001	; set this mode for transferring words
  sta $4300
  lda #$18		; $211[89]: VRAM data write
  sta $4301		; set destination

  ldy #$0000		; write to vram from $0000
  sty $2116

  lda #%00000001	; start DMA, channel 0
  sta $420B

  ; step 2
  ; 
  ; create tilemaps for bg1 & bg2
  lda #%10000000	; VRAM writing mode
  sta $2115
  ldx #$4000		; write to VRAM
  stx $2116		; from $4000

  ; "ugly code starts here. it writes the # shape
  .rept 2
    ; X|X|X
    .rept 2
      ldx #$0000	; tile 0 ( )
      stx $2118
      ldx #$0002	; tile 2 (|)
      stx $2118
    .endr
    ldx #$0000
    stx $2118
    
    ; first line finished, add BG's
    .rept 27
      stx $2118		; X=0
    .endr

    ; beginning of second line
    ; -+-+-
    .rept 2
      ldx #$0004	; tile 4 (-)
      stx $2118	
      ldx #$0006	; tile 6 (+)
      stx $2118
    .endr
    ldx #$0004		; tile 4 (-)
    stx $2118
    ldx #$0000
    .rept 27
      stx $2118
    .endr
  .endr
  .rept 2
    ldx #$0000		; tile 0 ( )
    stx $2118
    ldx #$0002		; tile 2 (|)
    stx $2118
  .endr
  ; "After I wrote this, I realized that I could have used a table, then copy data from there, but I leave this to you as a homework :) Set up BG2:"

  ldx #$6000		; BG2 will start here
  stx $2116
  ldx #$000C		; And will contain 1 tile
  stx $2118

  ; step 3: "set up video mode and interrupts, then loop forever
  ;
  ; set up screen
  lda #%00110000	; 16x16 tiles, mode 0
  sta $2105		; screen mode register
  lda #%01000000	; data starts from $4000
  sta $2107		; for BG1
  lda #%01100000	; and $6000
  sta $2108		; for BG2
  stz $210B		; BG1 and BG2 use the $0000 tiles
  lda #%00000011	; enable BG1 and 2
  sta $212C

  ; "PPU does not process top line so we scroll down one line"
  rep #$20		; 16bit a register
  lda #$07FF		; this is -1 for BG1
  sep #$20		; 8bit a
  sta $210E		; BG1 vert scroll
  xba
  sta $210E	

  rep #$20		; 16 bit a
  lda #$FFFF		; this is a -1 for BG2
  sep #$20		; 8bit a
  sta $2110		; BG2 vert scroll
  xba
  sta $2110

  lda #%00001111	; enable screen, set brightness to 15
  sta $2100

  lda #%10000001	; enable NMI and joypads bro
  sta $4200

  ; The O's and X's: they are a 3x3 tile
  ; 
  ; draft   Our info in the RAM   Info for the SNES in VRAM
  ; X|X|X    $0000|$0001|$0002    $4000|$4002|$4004 (27 empty tiles here)
  ; -+-+-    -----+-----+-----    -----+-----+----- (here, too)
  ; X|X|X => $0003|$0004|$0005 => $4040|$4042|$4044 (and so on)
  ; -+-+-    -----+-----+-----    -----+-----+-----
  ; X|X|X    $0006|$0007|$0008    $4080|$4082|$4084

forever:
wai
jmp forever
;--------------------------------------
.ends

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; step 1
; For now, use my file [tiles.inc]. We’ll transfer the tiles using DMA, and the palette using the old-school method. 
; Put this code after everything, this will put the tiles and the palette into the ROM.
.bank 1 slot 0       ; We'll use bank 1
.org 0
.section "Tiledata"
.include "tiles.inc" ; If you are using your own tiles, replace this
.ends
