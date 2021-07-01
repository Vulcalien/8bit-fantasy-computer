; Copyright 2021 Vulcalien
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, version 2 only.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along
; with this program; if not, write to the Free Software Foundation, Inc.,
; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

; the OS is located in the last 8 addressable pages
* = $f800

; --- RESET ---
reset:
.(
    sei
    cld

    ; set stack pointer to $ff
    ldx #$ff
    txs

    cli
.)

; --- COMMAND LINE ---
command_line:
.(
    ; DEBUG testing draw_character
    sta $5000

    lda #0
    pha ; y
    pha ; x

    lda #7
    pha ; color

    lda 33
    pha ; ascii char

    jsr draw_character


    ; TODO
    jmp *
.)

; --- FONT ---
; Each bit represents a pixel
; There are two types of characters - 3x5 and 5x5
;
; 3x5 characters have the first bit set to 0 and use 2 bytes
;
; 5x5 characters have the first bit set to 1 and use 4 bytes
; but the last 6 bits are for padding
font:
.(
    ; "font" is an array of pointers to characters
    .word char_32, char_33, char_34, char_35, char_36, char_37

    char_32: ; white space
        .byt %00000000, %00000000
    char_33: ; !
        .byt %00100100, %10000010
    char_34: ; "
        .byt %01011010, %00000000
    char_35: ; #
        .byt %10101011, %11101010, %11111010, %10000000
    char_36: ; $ TODO
        .byt %10000000, %00000000, %00000000, %00000000
    char_37: ; %
        .byt %11000100, %01000100, %01000100, %01000000
.)

; --- DRAW CHARACTER ---
draw_character:
.(
    tsx

    ; arguments and variables
    arg_char  = $0100-3
    arg_color = $0100-4
    arg_x     = $0100-5
    arg_y     = $0100-6

    zpg_sprite_ptr = $00
    zpg_write_addr = $02

    ; -----
    cld

    ; load the address of the pointer into Y register
    ; address = (var_char - 32) * 2
    lda arg_char,X
    sec
    sbc #32
    asl
    tay

    ; copy the pointer to the zero page
    lda font,Y
    sta zpg_sprite_ptr

    iny
    lda font,Y
    sta zpg_sprite_ptr+1

    ; read the first byte
    lda #0
    pha
    var_current_byte = $0100

    ldy #0
    lda (zpg_sprite_ptr),Y
    sta var_current_byte,X

    ; initialize zpg_write_addr
    ; arg_x and arg_y only use 7 bits

    ; all of arg_x's 7 bits are on the low byte
    lda arg_x,X
    and #%01111111

    ; while arg_y's 0-bit is on the low byte
    ; and the remaining go to the high byte
    ldy arg_y,X
    .(
    ; if arg_y is negative, then the 7-bit is set
    bpl do_nothing
    ora #%10000000
    do_nothing:
    .)
    sta zpg_write_addr

    ; now calculate the high byte
    tya
    lsr
    and %00111111

    ; add the first page used by the screen
    clc
    adc $10

    sta zpg_write_addr+1

    and #%10000000

    ; check if the given character is 5x5 or 3x5
    .(
    ; create bitmask variable
    lda #%00000001
    pha
    var_bitmask = $0100+1

    beq if_5by5
    else_5by5:
        lda #0
        pha
        var_y_counter = $0100+2

        pha
        var_x_counter = $0100+3

        lda #1
        pha
        var_byte_to_read = $0100+4

        .(
        loop_y:
        lda var_y_counter,X
        cmp #3
        beq end_y_loop

        .(
        loop_x:
            lda var_x_counter,X
            cmp #5
            beq end_x_loop

            lda var_current_byte,X
            and var_bitmask,X

            ; if the desired bit is set, then write a pixel
            .(
            beq dont_write

            lda arg_color,X
            ldy #0
            sta (zpg_write_addr),Y

            dont_write:
            .)

            lda var_bitmask,X
            rol
            sta var_bitmask,X

            ; if the bitmask is 1 again, that means
            ; that 8 bits have already been used
            ; so it's time to read the next byte
            cmp #1
            .(
            bne do_nothing

            ldy var_byte_to_read,X
            lda (zpg_sprite_ptr),Y
            inc var_byte_to_read,X

            do_nothing:
            .)

            ; TODO increase x coordinate

            inc var_x_counter,X
            end_x_loop:
        .)

        ; TODO increase y coordinate

        inc var_y_counter,X
        end_y_loop:
        .)

        pla     ; x counter
        pla     ; y counter
        jmp end_5by5
    if_5by5:
        ; TODO use the code used for 3x5
        ; the only difference should be the loop counters
        ; and the remaining bits

    end_5by5:

    pla     ; var_bitmask
    .)
    pla     ; var_current_byte

    rts
.)

; padding between code and the vectors
.(
start_of_padding:
    * = $fffa
    .dsb (* - start_of_padding), $00
    * = $fffa
.)

; --- VECTORS ---
vectors:
    ; TODO interrupt vectors
    .word $0000 ; nmi
    .word reset ; reset
    .word $0000 ; irq
