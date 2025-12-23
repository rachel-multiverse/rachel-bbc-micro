; =============================================================================
; BBC MICRO DISPLAY MODULE (Mode 7)
; =============================================================================

; -----------------------------------------------------------------------------
; Initialize display
; -----------------------------------------------------------------------------
.display_init
    LDA #22             ; VDU 22 - select mode
    JSR OSWRCH
    LDA #7              ; Mode 7 (teletext)
    JSR OSWRCH
    RTS

; -----------------------------------------------------------------------------
; Set cursor position
; Input: X = column (0-39), Y = row (0-24)
; -----------------------------------------------------------------------------
.set_cursor
    STX zp_cursor_x
    STY zp_cursor_y
    LDA #31             ; VDU 31 - position cursor
    JSR OSWRCH
    TXA
    JSR OSWRCH
    TYA
    JSR OSWRCH
    RTS

; -----------------------------------------------------------------------------
; Print character at cursor
; Input: A = character
; -----------------------------------------------------------------------------
.print_char
    JSR OSWRCH
    RTS

; -----------------------------------------------------------------------------
; Print null-terminated string
; Input: zp_ptr = string address
; -----------------------------------------------------------------------------
.print_string
    LDY #0
.ps_loop
    LDA (zp_ptr),Y
    BEQ ps_done
    JSR OSWRCH
    INY
    BNE ps_loop
.ps_done
    RTS

; -----------------------------------------------------------------------------
; Clear a row
; Input: Y = row number
; -----------------------------------------------------------------------------
.clear_row
    LDX #0
    JSR set_cursor
    LDX #SCREEN_WIDTH
    LDA #' '
.cr_loop
    JSR OSWRCH
    DEX
    BNE cr_loop
    RTS

; -----------------------------------------------------------------------------
; Draw horizontal border
; Input: Y = row number
; -----------------------------------------------------------------------------
.draw_border
    LDX #0
    JSR set_cursor
    LDX #SCREEN_WIDTH
    LDA #'-'
.db_loop
    JSR OSWRCH
    DEX
    BNE db_loop
    RTS

; -----------------------------------------------------------------------------
; Print a card (2 characters: rank + suit)
; Input: A = card byte
; -----------------------------------------------------------------------------
.print_card
    STA zp_temp3

    AND #$0F
    TAX
    LDA rank_chars,X
    JSR OSWRCH

    LDA zp_temp3
    LSR A
    LSR A
    LSR A
    LSR A
    AND #$03
    TAX
    LDA suit_chars,X
    JSR OSWRCH

    RTS

.rank_chars
    EQUS "?A23456789TJQK"

.suit_chars
    EQUS "HDCS"
