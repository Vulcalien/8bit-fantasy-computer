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

; --- RESET --- ;
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

; --- VECTORS ---
start_of_padding:
    * = $fffa
    .dsb (* - start_of_padding), $00
    * = $fffa

    ; TODO interrupt vectors
    .word $0000 ; nmi
    .word reset ; reset
    .word $0000 ; irq
