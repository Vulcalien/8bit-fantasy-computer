; --- DRAW CHARACTER ---
; parameters:
;   - ascii_char
;   - color
;   - x
;   - y
.(
draw_character:
    ; addresses
    zpg_char_ptr = $00
    zpg_setpix_addr = $02
    first_screen_page = $10

    cld

    ; load ascii_char and calculate the font char pointer address
    ; addr = (ascii_char - 32) * 2
    tsx
    lda $1000-6,X
    sed
    sbc #(32)
    asl
    tay

    ; write the pointer to zero page
    lda font,Y
    sta zpg_char_ptr

    iny
    lda font,Y
    sta zpg_char_ptr+1

    ; get the first byte
    ldy #0
    lda (zpg_char_ptr),Y

    calculate_setpix_addr:
        ; make sure that x coordinate is >= 127
        lda $1000-4,X
        and #%01111111
        sta $1000-4,X

        ; read y coordinate
        lda $1000-3,X
        ror ; we only care about the first bit
        and #%10000000

        ; read x coordinate
        ora $1000-4,X
        sta zpg_setpix_addr

        ; read y coordinate again
        ; but only use the most valuable 6 bits
        lda $1000-3,X
        lsr
        and #%00111111

        ; add the first page of the screen
        clc
        adc first_screen_page

    ; check if the "5x5 char flag" is set
    and #%10000000
    bne larger_char
    normal_char:
        bits_counter = $1000
        lda #7
        pha

        ldy #0
        lda (zpg_char_ptr),Y

        lsr ; ignore first bit
        bmi after_set_pixel ; if negative don't set pixel

        ; set pixel


        after_set_pixel:
            dec bits_counter,X

            ; if it's zero, then read new byte
            beq read_new_byte
            lsr
            read_new_byte:
                iny
                lda (zpg_char_ptr),Y

            after_read_new_byte:



        pla

        clc
        bcc end_of_char_branch
    larger_char:
        ; TODO
        jmp *
    end_of_char_branch:
.)
