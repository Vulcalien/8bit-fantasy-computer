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
    sei                             ; disable interrupts
    cld                             ; disable decimal mode

    ; set stack pointer to $ff
    ldx #$ff                        ; X = $ff
    txs                             ; SP = X

    cli                             ; allow interrupts

    jmp command_line                ;
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

    pla
    pla
    pla
    pla

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
    tsx                             ; X = SP

    ; arguments
    arg_char  = $0100-3             ;
    arg_color = $0100-4             ;
    arg_x     = $0100-5             ;
    arg_y     = $0100-6             ;

    zpg_sprite_ptr = $00
    zpg_write_addr = $02

    cld                             ; disable decimal mode

    ; load the address of the pointer into Y register
    ; address = (arg_char - 32) * 2
    lda arg_char,X                  ; A = arg_char
    sec                             ; C = 1
    sbc #32                         ; A -= 32
    asl                             ; A *= 2 ; pointers are 2 bytes in size
    tay                             ; Y = A

    lda font,Y                      ; A = low byte ; Y is used as index
    sta zpg_sprite_ptr              ; zpg_sprite_ptr LO = A

    lda font+1,Y                    ; A = high byte
    sta zpg_sprite_ptr+1            ; zpg_sprite_ptr HI = A

    ; read the first char byte
    pha                             ; var_current_byte = ?
    var_current_byte = $0100        ;

    ldy #0                          ; Y = 0
    lda (zpg_sprite_ptr),Y          ; A = (zpg_sprite_ptr),Y
    sta var_current_byte,X          ; var_current_byte = A

    ; check if the given character is 5x5 or 3x5
    .(
    ; create bitmask variable
    lda #%00000001                  ; var_bitmask = %00000001
    pha                             ;
    var_bitmask = $0100+1           ;

    lda var_current_byte,X          ; A = var_current_byte
    bmi if_5by5                     ; if bit-7 is set (it is when the char is 5x5)
    else_5by5:
        lda #0                          ; var_y_counter = 0
        pha                             ;
        var_y_counter = $0100+2         ;

        pha                             ; var_x_counter = 0 (avoid lda again)
        var_x_counter = $0100+3         ;

        lda #1                          ; var_byte_to_read = 1
        pha                             ;
        var_byte_to_read = $0100+4      ;

        pha                             ; var_y_pix = ?
        var_y_pix = $0100+5             ;

        .(
        loop_y:
            lda var_y_counter,X             ; A = var_y_counter
            cmp #3                          ;
            beq end_loop_y                  ; if A == 3 -> exit loop_y

            ; calculate y coordinate
            ; var_y_pix = (arg_y + var_y_counter) & %01111111
            clc                             ; C = 0
            adc arg_y,X                     ; A (value var_y_counter) += arg_y
            and #%01111111                  ; A &= %01111111 ; y cannot be >= 128
            sta var_y_pix,X                 ; var_y_pix = A

            ; set low byte, where the first bit of y becomes bit-7
            ror                             ; rotate right A (value var_y_pix)
            and %10000000                   ; A &= %10000000
            sta zpg_write_addr              ; zpg_write_addr LO = A

            ; set high byte
            lda var_y_pix,X                 ; A = var_y_pix
            asl                             ; A >>= 1 ; the first bit is in the low byte
            clc                             ; C = 0
            adc #$10                        ; A += $10 (the first page used by screen)
            sta zpg_write_addr+1            ; zpg_write_addr HI = A

            .(
            loop_x:
                lda var_x_counter,X             ; A = var_x_counter
                cmp #5                          ;
                beq end_loop_x                  ; if A == 5 -> exit loop_x

                ; calculate x coordinate (and use it directly, without storing it)
                ; var_x_pix = (arg_x + var_x_counter) & %01111111
                clc                             ; C = 0
                adc arg_x,X                     ; A (value var_x_counter) += arg_x
                and #%01111111                  ; A &= %01111111 ; x cannot be >= 128

                ; the value stored by the loop_y
                ; (bit-7) must be considered
                ora zpg_write_addr              ; A |= zpg_write_addr LO
                sta zpg_write_addr              ; zpg_write_addr LO = A

                ; if the desired bit is set, then write a pixel
                .(
                lda var_current_byte,X          ; A = var_current_byte
                and var_bitmask,X               ; A &= var_bitmask
                beq dont_write                  ; if A == 0 -> goto dont_write

                    lda arg_color,X                 ; A = arg_color
                    ldy #0                          ; Y = 0
                    sta (zpg_write_addr),Y          ; write A to ptr (zpg_write_addr),Y

                dont_write:
                .)

                rol var_bitmask,X               ; rotate left var_bitmask

                ; if the bitmask is 1 again, this means
                ; that 8 bits have already been used
                ; so it's time to read the next byte
                .(
                lda var_bitmask,X               ; A = var_bitmask
                cmp #1                          ;
                bne do_nothing                  ; if A != 1 -> goto do_nothing

                    ; read next byte
                    ldy var_byte_to_read,X          ; Y = var_byte_to_read
                    lda (zpg_sprite_ptr),Y          ; A = (zpg_sprite_ptr),Y
                    inc var_byte_to_read,X          ; var_byte_to_read++

                do_nothing:
                .)

                inc var_x_counter,X             ; var_x_counter++
            end_loop_x:
            .)

            inc var_y_counter,X             ; var_y_counter++
        end_loop_y:
        .)

        jmp end_5by5
    if_5by5:
        ; TODO use the code used for 3x5
        ; the only difference should be the loop counters
        ; and the remaining bits

    end_5by5:

    .)

    txs                             ; SP = X ; deallocate all local variables
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
