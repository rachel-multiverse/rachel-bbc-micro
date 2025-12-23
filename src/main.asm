; =============================================================================
; RACHEL BBC MICRO CLIENT - Main Entry Point
; =============================================================================
; BeebAsm format - generates bootable disc

ORG $1900
GUARD $7C00

INCLUDE "equates.asm"

; =============================================================================
; ENTRY POINT
; =============================================================================

.main
    JSR display_init
    JSR draw_title_screen
    JSR wait_key

.main_connect
    JSR display_init
    JSR input_ip_address
    JSR do_connect
    BNE main_connect        ; Retry on failure

    JSR wait_for_game
    BNE main_connect        ; Back to connect on cancel

    JSR draw_game_screen

.main_loop
    JSR net_available
    BEQ ml_input

    JSR rubp_receive
    JSR rubp_validate
    BNE ml_input

    JSR rubp_get_type

    CMP #MSG_GAME_STATE
    BNE ml_chk_end
    JSR rubp_parse_game_state
    JSR redraw_game
    JMP ml_input

.ml_chk_end
    CMP #MSG_GAME_END
    BNE ml_input
    JSR draw_game_end
    JSR wait_key
    JMP main_connect

.ml_input
    LDA CURRENT_TURN
    CMP MY_INDEX
    BNE main_loop           ; Not our turn

    JSR check_key
    BEQ main_loop

    CMP #KEY_LEFT
    BEQ ml_left
    CMP #KEY_RIGHT
    BEQ ml_right
    CMP #KEY_SPACE
    BEQ ml_select
    CMP #KEY_RETURN
    BEQ ml_play
    CMP #KEY_D
    BEQ ml_draw
    CMP #KEY_d
    BEQ ml_draw
    CMP #KEY_ESC
    BEQ ml_quit

    JMP main_loop

.ml_left
    LDA CURSOR_POS
    BEQ main_loop
    DEC CURSOR_POS
    JSR draw_hand
    JMP main_loop

.ml_right
    LDA CURSOR_POS
    CLC
    ADC #1
    CMP HAND_COUNT
    BCS main_loop
    STA CURSOR_POS
    JSR draw_hand
    JMP main_loop

.ml_select
    JSR toggle_selected
    JSR draw_hand
    JMP main_loop

.ml_play
    JSR count_selected
    BNE ml_play_cont
    JMP main_loop           ; Nothing selected
.ml_play_cont

    JSR check_needs_nomination
    BEQ ml_no_nom

    JSR get_suit_nomination
    JMP ml_send_play

.ml_no_nom
    LDA #$FF                ; No nomination

.ml_send_play
    JSR rubp_send_play_card
    LDA #0
    STA SELECTED_LO
    STA SELECTED_HI
    JMP main_loop

.ml_draw
    LDA #1
    JSR rubp_send_draw_card
    JMP main_loop

.ml_quit
    JSR net_close
    JMP main_connect

; =============================================================================
; TITLE SCREEN
; =============================================================================

.draw_title_screen
    LDX #16
    LDY #5
    JSR set_cursor
    LDA #<title_1
    STA zp_ptr
    LDA #>title_1
    STA zp_ptr+1
    JSR print_string

    LDX #13
    LDY #8
    JSR set_cursor
    LDA #<title_2
    STA zp_ptr
    LDA #>title_2
    STA zp_ptr+1
    JSR print_string

    LDX #12
    LDY #10
    JSR set_cursor
    LDA #<title_3
    STA zp_ptr
    LDA #>title_3
    STA zp_ptr+1
    JSR print_string

    LDX #10
    LDY #14
    JSR set_cursor
    LDA #<title_4
    STA zp_ptr
    LDA #>title_4
    STA zp_ptr+1
    JSR print_string

    LDX #12
    LDY #20
    JSR set_cursor
    LDA #<title_5
    STA zp_ptr
    LDA #>title_5
    STA zp_ptr+1
    JSR print_string

    RTS

.title_1
    EQUS "RACHEL", 0
.title_2
    EQUS "THE CARD GAME", 0
.title_3
    EQUS "BBC MICRO CLIENT", 0
.title_4
    EQUS "NETWORK REQUIRED", 0
.title_5
    EQUS "PRESS ANY KEY", 0

; =============================================================================
; GAME END SCREEN
; =============================================================================

.draw_game_end
    LDX #11
    LDY #12
    JSR set_cursor
    LDA #<end_msg
    STA zp_ptr
    LDA #>end_msg
    STA zp_ptr+1
    JSR print_string
    RTS

.end_msg
    EQUS "*** GAME OVER ***", 0

; =============================================================================
; TOGGLE CARD SELECTION
; =============================================================================

.toggle_selected
    LDA CURSOR_POS
    CMP #8
    BCS ts_high

    TAX
    LDA #1
.ts_shift_lo
    CPX #0
    BEQ ts_do_lo
    ASL A
    DEX
    BNE ts_shift_lo
.ts_do_lo
    EOR SELECTED_LO
    STA SELECTED_LO
    RTS

.ts_high
    SEC
    SBC #8
    TAX
    LDA #1
.ts_shift_hi
    CPX #0
    BEQ ts_do_hi
    ASL A
    DEX
    BNE ts_shift_hi
.ts_do_hi
    EOR SELECTED_HI
    STA SELECTED_HI
    RTS

; =============================================================================
; CHECK IF NOMINATION NEEDED
; =============================================================================

.check_needs_nomination
    LDX #0
    LDA SELECTED_LO
    STA zp_temp1
    LDA SELECTED_HI
    STA zp_temp2

.cnn_loop
    LDA zp_temp1
    AND #1
    BEQ cnn_next

    LDA MY_HAND,X
    AND #$0F
    CMP #RANK_ACE
    BEQ cnn_yes

.cnn_next
    LSR zp_temp2
    ROR zp_temp1
    INX
    CPX HAND_COUNT
    BCC cnn_loop

    LDA #0
    RTS

.cnn_yes
    LDA #1
    RTS

; =============================================================================
; GET SUIT NOMINATION
; =============================================================================

.get_suit_nomination
    LDX #1
    LDY #22
    JSR set_cursor
    LDA #<nom_prompt
    STA zp_ptr
    LDA #>nom_prompt
    STA zp_ptr+1
    JSR print_string

.gsn_wait
    JSR wait_key
    CMP #'H'
    BEQ gsn_hearts
    CMP #'h'
    BEQ gsn_hearts
    CMP #'D'
    BEQ gsn_diamonds
    CMP #'d'
    BEQ gsn_diamonds
    CMP #'C'
    BEQ gsn_clubs
    CMP #'c'
    BEQ gsn_clubs
    CMP #'S'
    BEQ gsn_spades
    CMP #'s'
    BEQ gsn_spades
    JMP gsn_wait

.gsn_hearts
    LDA #SUIT_HEARTS
    RTS
.gsn_diamonds
    LDA #SUIT_DIAMONDS
    RTS
.gsn_clubs
    LDA #SUIT_CLUBS
    RTS
.gsn_spades
    LDA #SUIT_SPADES
    RTS

.nom_prompt
    EQUS "SUIT? H/D/C/S: ", 0

; =============================================================================
; HELPER FUNCTIONS
; =============================================================================

; Input IP address from user
.input_ip_address
    JSR get_server_address
    RTS

; Perform connection
.do_connect
    JSR show_connecting
    LDA #<server_ip
    STA zp_ptr
    LDA #>server_ip
    STA zp_ptr+1
    LDX conn_port
    LDY conn_port+1
    JSR connect_server
    BCS dc_fail
    LDA #0
    RTS
.dc_fail
    JSR show_connect_error
    LDA #1
    RTS

; Wait for game to start
.wait_for_game
    LDX #10
    LDY #12
    JSR set_cursor
    LDA #<wfg_msg
    STA zp_ptr
    LDA #>wfg_msg
    STA zp_ptr+1
    JSR print_string
.wfg_loop
    JSR check_key
    CMP #KEY_ESC
    BEQ wfg_cancel
    JSR net_recv
    BCS wfg_loop
    JSR receive_message
    CMP #MSG_GAME_START
    BNE wfg_loop
    LDA #0
    RTS
.wfg_cancel
    LDA #1
    RTS

.wfg_msg
    EQUS "WAITING FOR GAME...", 0

; Check if network data available
.net_available
    LDA ACIA_STATUS
    AND #ACIA_RDRF
    RTS

; RUBP receive wrapper
.rubp_receive
    JSR net_recv
    RTS

; Validate RUBP message
.rubp_validate
    LDA rx_buffer
    CMP #'R'
    BNE rv_bad
    LDA rx_buffer+1
    CMP #'A'
    BNE rv_bad
    LDA rx_buffer+2
    CMP #'C'
    BNE rv_bad
    LDA rx_buffer+3
    CMP #'H'
    BNE rv_bad
    LDA #0
    RTS
.rv_bad
    LDA #1
    RTS

; Get message type
.rubp_get_type
    LDA rx_buffer+6
    RTS

; Parse game state from buffer
.rubp_parse_game_state
    JSR process_game_state
    RTS

; Count selected cards
.count_selected
    LDA SELECTED_LO
    STA zp_temp1
    LDA SELECTED_HI
    STA zp_temp2
    LDA #0
    LDX #16
.cs_count
    LSR zp_temp2
    ROR zp_temp1
    BCC cs_next
    CLC
    ADC #1
.cs_next
    DEX
    BNE cs_count
    RTS

; Send play card message
.rubp_send_play_card
    STA nominated_suit
    JSR count_selected
    TAX
    JSR send_play_cards
    RTS

; Send draw card message
.rubp_send_draw_card
    JSR send_draw
    RTS

; =============================================================================
; INCLUDES
; =============================================================================

INCLUDE "display.asm"
INCLUDE "input.asm"
INCLUDE "game.asm"
INCLUDE "connect.asm"
INCLUDE "rubp.asm"
INCLUDE "net/wifi.asm"

; =============================================================================
; DATA SECTION
; =============================================================================

.CONN_STATE     EQUB 0
.CURRENT_TURN   EQUB 0
.DIRECTION      EQUB 1
.DISCARD_TOP    EQUB 0
.NOMINATED_SUIT EQUB $FF
.DECK_COUNT     EQUB 52
.PENDING_DRAWS  EQUB 0
.PENDING_SKIPS  EQUB 0
.PLAYER_COUNT   EQUB 0
.MY_INDEX       EQUB 0

.HAND_COUNT     EQUB 0
.CURSOR_POS     EQUB 0
.SELECTED_LO    EQUB 0
.SELECTED_HI    EQUB 0

.PLAYER_ID_HI   EQUB 0
.PLAYER_ID_LO   EQUB 0
.GAME_ID_HI     EQUB 0
.GAME_ID_LO     EQUB 0
.SEQUENCE_HI    EQUB 0
.SEQUENCE_LO    EQUB 0

.PLAYER_COUNTS  EQUB 0, 0, 0, 0, 0, 0, 0, 0

.MY_HAND        SKIP 32
.IP_INPUT_BUF   SKIP 32
.SERIAL_TX_BUF  SKIP 64
.SERIAL_RX_BUF  SKIP 64

.end

SAVE "RACHEL", main, end, main
