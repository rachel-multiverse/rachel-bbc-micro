; =============================================================================
; BBC MICRO GAME MODULE
; =============================================================================

; -----------------------------------------------------------------------------
; Draw the complete game screen
; -----------------------------------------------------------------------------
.draw_game_screen
    JSR display_init

    LDX #14
    LDY #0
    JSR set_cursor
    LDA #<gm_title
    STA zp_ptr
    LDA #>gm_title
    STA zp_ptr+1
    JSR print_string

    LDY #1
    JSR draw_border
    LDY #4
    JSR draw_border
    LDY #10
    JSR draw_border
    LDY #18
    JSR draw_border
    LDY #20
    JSR draw_border

    LDX #1
    LDY #11
    JSR set_cursor
    LDA #<gm_hand
    STA zp_ptr
    LDA #>gm_hand
    STA zp_ptr+1
    JSR print_string

    LDX #1
    LDY #19
    JSR set_cursor
    LDA #<gm_ctrl
    STA zp_ptr
    LDA #>gm_ctrl
    STA zp_ptr+1
    JSR print_string

    RTS

.gm_title   EQUS "RACHEL V1.0", 0
.gm_hand    EQUS "YOUR HAND:", 0
.gm_ctrl    EQUS "<-> MOVE  SPC SELECT  RET PLAY", 0

; -----------------------------------------------------------------------------
; Full game redraw
; -----------------------------------------------------------------------------
.redraw_game
    JSR draw_players
    JSR draw_discard
    JSR draw_hand
    JSR draw_turn_indicator
    RTS

; =============================================================================
; PLAYER LIST
; =============================================================================

.draw_players
    LDX #0
    LDY #2
    JSR set_cursor

    LDA #0
.dp_loop1
    STA dp_idx
    JSR draw_one_player
    LDA dp_idx
    CLC
    ADC #1
    CMP #4
    BCC dp_loop1

    LDX #0
    LDY #3
    JSR set_cursor

    LDA #4
.dp_loop2
    STA dp_idx
    JSR draw_one_player
    LDA dp_idx
    CLC
    ADC #1
    CMP #8
    BCC dp_loop2

    RTS

.dp_idx EQUB 0

.draw_one_player
    LDA #'P'
    JSR OSWRCH
    LDA dp_idx
    CLC
    ADC #'1'
    JSR OSWRCH
    LDA #':'
    JSR OSWRCH

    LDX dp_idx
    LDA PLAYER_COUNTS,X
    JSR print_number_2d

    LDA #' '
    JSR OSWRCH
    JSR OSWRCH
    RTS

.print_number_2d
    STA zp_temp4
    LDX #0
.pn2d_tens
    CMP #10
    BCC pn2d_print
    SEC
    SBC #10
    INX
    BNE pn2d_tens
.pn2d_print
    STA zp_temp4
    TXA
    ORA #'0'
    JSR OSWRCH
    LDA zp_temp4
    ORA #'0'
    JSR OSWRCH
    RTS

; =============================================================================
; DISCARD PILE
; =============================================================================

.draw_discard
    LDX #14
    LDY #6
    JSR set_cursor
    LDA #<dd_lbl
    STA zp_ptr
    LDA #>dd_lbl
    STA zp_ptr+1
    JSR print_string

    LDX #16
    LDY #7
    JSR set_cursor

    LDA DISCARD_TOP
    BEQ dd_empty
    JSR print_card
    JMP dd_suit

.dd_empty
    LDA #<dd_mt
    STA zp_ptr
    LDA #>dd_mt
    STA zp_ptr+1
    JSR print_string
    RTS

.dd_suit
    LDA NOMINATED_SUIT
    CMP #$FF
    BEQ dd_done

    LDX #14
    LDY #8
    JSR set_cursor
    LDA #<dd_st_lbl
    STA zp_ptr
    LDA #>dd_st_lbl
    STA zp_ptr+1
    JSR print_string

    LDA NOMINATED_SUIT
    JSR print_suit_name

.dd_done
    RTS

.dd_lbl     EQUS "DISCARD:", 0
.dd_mt      EQUS "[EMPTY]", 0
.dd_st_lbl  EQUS "SUIT: ", 0

.print_suit_name
    AND #3
    ASL A
    TAX
    LDA sn_ptrs,X
    STA zp_ptr
    LDA sn_ptrs+1,X
    STA zp_ptr+1
    JSR print_string
    RTS

.sn_ptrs    EQUW sn_h, sn_d, sn_c, sn_s
.sn_h       EQUS "HEARTS", 0
.sn_d       EQUS "DIAMONDS", 0
.sn_c       EQUS "CLUBS", 0
.sn_s       EQUS "SPADES", 0

; =============================================================================
; HAND DISPLAY
; =============================================================================

.draw_hand
    LDA HAND_COUNT
    BNE dh_has_cards

    LDX #1
    LDY #12
    JSR set_cursor
    LDA #<dh_empty
    STA zp_ptr
    LDA #>dh_empty
    STA zp_ptr+1
    JSR print_string
    RTS

.dh_has_cards
    LDX #1
    LDY #12
    JSR set_cursor

    LDA #0
    STA dh_pos
    STA dh_col

.dh_loop
    LDA dh_pos
    JSR check_selected
    BEQ dh_not_sel

    LDA #'['
    JSR OSWRCH
    JMP dh_card

.dh_not_sel
    LDA dh_pos
    CMP CURSOR_POS
    BNE dh_not_cur

    LDA #'>'
    JSR OSWRCH
    JMP dh_card

.dh_not_cur
    LDA #' '
    JSR OSWRCH

.dh_card
    LDX dh_pos
    LDA MY_HAND,X
    JSR print_card

    LDA dh_pos
    JSR check_selected
    BEQ dh_no_close
    LDA #']'
    JSR OSWRCH
    JMP dh_space
.dh_no_close
    LDA #' '
    JSR OSWRCH

.dh_space
    INC dh_pos
    INC dh_col

    LDA dh_col
    CMP #6
    BNE dh_no_newline

    LDA #0
    STA dh_col

    LDA dh_pos
    LSR A
    LSR A
    CLC
    ADC #12
    TAY
    LDX #1
    JSR set_cursor

.dh_no_newline
    LDA dh_pos
    CMP HAND_COUNT
    BCC dh_loop

    RTS

.dh_pos     EQUB 0
.dh_col     EQUB 0
.dh_empty   EQUS "(NO CARDS)", 0

; -----------------------------------------------------------------------------
; Check if card selected
; -----------------------------------------------------------------------------
.check_selected
    CMP #8
    BCS cks_high

    TAX
    LDA SELECTED_LO
    JMP cks_shift

.cks_high
    SEC
    SBC #8
    TAX
    LDA SELECTED_HI

.cks_shift
    CPX #0
    BEQ cks_test
.cks_sloop
    LSR A
    DEX
    BNE cks_sloop

.cks_test
    AND #1
    RTS

; =============================================================================
; TURN INDICATOR
; =============================================================================

.draw_turn_indicator
    LDY #21
    JSR clear_row

    LDX #1
    LDY #21
    JSR set_cursor

    LDA CURRENT_TURN
    CMP MY_INDEX
    BNE dti_other

    LDA #<dti_your
    STA zp_ptr
    LDA #>dti_your
    STA zp_ptr+1
    JSR print_string
    RTS

.dti_other
    LDA #<dti_player
    STA zp_ptr
    LDA #>dti_player
    STA zp_ptr+1
    JSR print_string

    LDA CURRENT_TURN
    CLC
    ADC #'1'
    JSR OSWRCH

    LDA #<dti_turn
    STA zp_ptr
    LDA #>dti_turn
    STA zp_ptr+1
    JSR print_string
    RTS

.dti_your   EQUS ">>> YOUR TURN <<<", 0
.dti_player EQUS "PLAYER ", 0
.dti_turn   EQUS "'S TURN", 0
