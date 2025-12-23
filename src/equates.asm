; =============================================================================
; BBC MICRO EQUATES
; =============================================================================

; Zero page usage
zp_ptr      = $70
zp_ptr2     = $72
zp_temp1    = $74
zp_temp2    = $75
zp_temp3    = $76
zp_temp4    = $77
zp_cursor_x = $78
zp_cursor_y = $79

; MOS Entry Points
OSWRCH      = $FFEE     ; Write character
OSRDCH      = $FFE0     ; Read character (blocking)
OSBYTE      = $FFF4     ; OS byte call
OSWORD      = $FFF1     ; OS word call
OSCLI       = $FFF7     ; Execute * command
OSNEWL      = $FFE7     ; Output newline

; Screen memory (Mode 7)
SCREEN_BASE = $7C00
SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

; Key codes
KEY_LEFT    = 136       ; Cursor left
KEY_RIGHT   = 137       ; Cursor right
KEY_UP      = 139       ; Cursor up
KEY_DOWN    = 138       ; Cursor down
KEY_RETURN  = 13
KEY_SPACE   = 32
KEY_ESC     = 27
KEY_DELETE  = 127
KEY_D       = 'D'
KEY_d       = 'd'

; RUBP Protocol Constants
MAGIC_0     = 'R'
MAGIC_1     = 'A'
MAGIC_2     = 'C'
MAGIC_3     = 'H'
PROTOCOL_VER = 1

; Header offsets
HDR_MAGIC       = 0
HDR_VERSION     = 4
HDR_TYPE        = 5
HDR_FLAGS       = 6
HDR_RESERVED    = 7
HDR_SEQ         = 8
HDR_PLAYER_ID   = 10
HDR_GAME_ID     = 12
HDR_CHECKSUM    = 14
PAYLOAD_START   = 16
PAYLOAD_SIZE    = 48

; Message types
MSG_JOIN        = $01
MSG_LEAVE       = $02
MSG_READY       = $03
MSG_GAME_START  = $10
MSG_GAME_STATE  = $11
MSG_GAME_END    = $12
MSG_PLAY_CARDS  = $20
MSG_DRAW_CARD   = $21
MSG_NOMINATE    = $22
MSG_ACK         = $F0
MSG_NAK         = $F1

; Connection states
CONN_DISCONNECTED = 0
CONN_HANDSHAKE    = 1
CONN_WAITING      = 2
CONN_PLAYING      = 3

; Card constants
SUIT_HEARTS     = 0
SUIT_DIAMONDS   = 1
SUIT_CLUBS      = 2
SUIT_SPADES     = 3

RANK_ACE        = 1
RANK_JACK       = 11
RANK_QUEEN      = 12
RANK_KING       = 13
