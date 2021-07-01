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
    sei
    cld

    ; set stack pointer to $ff
    ldx #$ff
    txs

    cli

; --- COMMAND LINE ---
command_line:
    ; TODO
    jmp *

; --- FONT ---
; Each bit represents a pixel
; There are two types of characters - 3x5 and 5x5
;
; 3x5 characters have the first bit set to 0 and use 2 bytes
;
; 5x5 characters have the first bit set to 1 and use 4 bytes
; but the last 6 bits are for padding
font:
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
