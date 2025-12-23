; =============================================================================
; BBC MICRO RUBP PROTOCOL MODULE
; Rachel UDP Binary Protocol - 64-byte fixed messages
; Message types defined in equates.asm
; =============================================================================

; -----------------------------------------------------------------------------
; Initialize RUBP layer
; -----------------------------------------------------------------------------
.rubp_init
    LDA #0
    STA rubp_seq
    STA last_recv_seq
    RTS

.rubp_seq       EQUB 0
.last_recv_seq  EQUB 0

; -----------------------------------------------------------------------------
; Build message header
; Input: A = message type
; -----------------------------------------------------------------------------
.build_header
    STA msg_type_temp

    ; Magic "RACH"
    LDA #'R'
    STA tx_buffer
    LDA #'A'
    STA tx_buffer+1
    LDA #'C'
    STA tx_buffer+2
    LDA #'H'
    STA tx_buffer+3

    ; Version 1.0
    LDA #$01
    STA tx_buffer+4
    LDA #$00
    STA tx_buffer+5

    ; Message type
    LDA msg_type_temp
    STA tx_buffer+6

    ; Flags
    LDA #$00
    STA tx_buffer+7

    ; Sequence number (big-endian)
    LDA #$00
    STA tx_buffer+8
    LDA rubp_seq
    STA tx_buffer+9
    INC rubp_seq

    ; Player ID
    LDA player_id
    STA tx_buffer+10
    LDA player_id+1
    STA tx_buffer+11

    ; Game ID
    LDA game_id
    STA tx_buffer+12
    LDA game_id+1
    STA tx_buffer+13

    ; Reserved
    LDA #$00
    STA tx_buffer+14
    STA tx_buffer+15

    RTS

.msg_type_temp  EQUB 0
.player_id      EQUW 0
.game_id        EQUW 0

; -----------------------------------------------------------------------------
; Send JOIN message
; -----------------------------------------------------------------------------
.send_join
    LDA #MSG_JOIN
    JSR build_header

    ; Clear payload
    LDX #16
    LDA #0
.sj_clear
    STA tx_buffer,X
    INX
    CPX #64
    BNE sj_clear

    JSR net_send
    RTS

; -----------------------------------------------------------------------------
; Send READY message
; -----------------------------------------------------------------------------
.send_ready
    LDA #MSG_READY
    JSR build_header

    ; Clear payload
    LDX #16
    LDA #0
.sr_clear
    STA tx_buffer,X
    INX
    CPX #64
    BNE sr_clear

    JSR net_send
    RTS

; -----------------------------------------------------------------------------
; Send PLAY_CARDS message
; Input: X = number of cards, card_play_buf contains cards
; -----------------------------------------------------------------------------
.send_play_cards
    STX card_count_temp

    LDA #MSG_PLAY_CARDS
    JSR build_header

    ; Card count
    LDA card_count_temp
    STA tx_buffer+16

    ; Nominated suit ($FF = none)
    LDA nominated_suit
    STA tx_buffer+17

    ; Cards (up to 8)
    LDX #0
.spc_copy
    CPX card_count_temp
    BCS spc_pad
    LDA card_play_buf,X
    STA tx_buffer+18,X
    INX
    JMP spc_copy

.spc_pad
    CPX #8
    BCS spc_done
    LDA #0
    STA tx_buffer+18,X
    INX
    JMP spc_pad

.spc_done
    ; Clear rest of payload
    LDX #26
.spc_clear
    LDA #0
    STA tx_buffer,X
    INX
    CPX #64
    BNE spc_clear

    JSR net_send
    RTS

.card_count_temp    EQUB 0
.nominated_suit     EQUB $FF
.card_play_buf      EQUB 0,0,0,0,0,0,0,0

; -----------------------------------------------------------------------------
; Send DRAW_CARD message
; -----------------------------------------------------------------------------
.send_draw
    LDA #MSG_DRAW_CARD
    JSR build_header

    ; Clear payload
    LDX #16
    LDA #0
.sd_clear
    STA tx_buffer,X
    INX
    CPX #64
    BNE sd_clear

    JSR net_send
    RTS

; -----------------------------------------------------------------------------
; Receive and process message
; Returns: A = message type, or 0 if no message
; -----------------------------------------------------------------------------
.receive_message
    JSR net_recv
    BCC rm_got_msg
    LDA #0
    RTS

.rm_got_msg
    ; Validate magic
    LDA rx_buffer
    CMP #'R'
    BNE rm_invalid
    LDA rx_buffer+1
    CMP #'A'
    BNE rm_invalid
    LDA rx_buffer+2
    CMP #'C'
    BNE rm_invalid
    LDA rx_buffer+3
    CMP #'H'
    BNE rm_invalid

    ; Store sequence
    LDA rx_buffer+9
    STA last_recv_seq

    ; Return message type
    LDA rx_buffer+6
    RTS

.rm_invalid
    LDA #0
    RTS

; -----------------------------------------------------------------------------
; Process GAME_STATE message
; Updates local game state from rx_buffer
; -----------------------------------------------------------------------------
.process_game_state
    ; Current turn
    LDA rx_buffer+16
    STA CURRENT_TURN

    ; Direction
    LDA rx_buffer+17
    STA DIRECTION

    ; Discard top card
    LDA rx_buffer+18
    STA DISCARD_TOP

    ; Nominated suit
    LDA rx_buffer+19
    STA NOMINATED_SUIT

    ; Pending draws
    LDA rx_buffer+20
    STA PENDING_DRAWS

    ; Pending skips
    LDA rx_buffer+21
    STA PENDING_SKIPS

    ; Player counts (8 players)
    LDX #0
.pgs_counts
    LDA rx_buffer+22,X
    STA PLAYER_COUNTS,X
    INX
    CPX #8
    BNE pgs_counts

    ; My index
    LDA rx_buffer+30
    STA MY_INDEX

    ; My hand count
    LDA rx_buffer+31
    STA HAND_COUNT

    ; My hand (up to 16 cards)
    LDX #0
.pgs_hand
    LDA rx_buffer+32,X
    STA MY_HAND,X
    INX
    CPX #16
    BNE pgs_hand

    RTS

; -----------------------------------------------------------------------------
; TX/RX Buffers
; -----------------------------------------------------------------------------
.tx_buffer      EQUS STRING$(64, CHR$(0))
.rx_buffer      EQUS STRING$(64, CHR$(0))
