; =============================================================================
; BBC MICRO WIFI NETWORK DRIVER
; Supports WiFi adapters via serial port (e.g., ESP8266-based modems)
; =============================================================================

; Serial port registers (BBC Micro 6850 ACIA at $FE08)
ACIA_CTRL       = $FE08
ACIA_STATUS     = $FE08
ACIA_TX         = $FE09
ACIA_RX         = $FE09

; Status bits
ACIA_TDRE       = %00000010     ; Transmit Data Register Empty
ACIA_RDRF       = %00000001     ; Receive Data Register Full

; Connection state
.net_state      EQUB 0
NET_DISCONNECTED = 0
NET_CONNECTING   = 1
NET_CONNECTED    = 2

; -----------------------------------------------------------------------------
; Initialize network
; Returns: C clear on success
; -----------------------------------------------------------------------------
.net_init
    ; Initialize ACIA for 9600 baud
    LDA #$03            ; Master reset
    STA ACIA_CTRL
    LDA #$16            ; 8N1, divide by 64
    STA ACIA_CTRL

    ; Small delay for modem
    LDX #0
    LDY #0
.ni_delay
    DEX
    BNE ni_delay
    DEY
    BNE ni_delay

    ; Send AT to check modem
    JSR send_at
    BCS ni_fail

    LDA #NET_DISCONNECTED
    STA net_state
    CLC
    RTS

.ni_fail
    SEC
    RTS

; -----------------------------------------------------------------------------
; Connect to server
; Input: server_ip = IP address, conn_port = port
; Returns: C clear on success
; -----------------------------------------------------------------------------
.net_connect
    LDA #NET_CONNECTING
    STA net_state

    ; Build AT+CIPSTART command
    LDA #<at_connect
    STA zp_ptr
    LDA #>at_connect
    STA zp_ptr+1
    JSR send_string

    ; Send IP address
    LDX #0
.nc_ip_loop
    LDA server_ip,X
    JSR send_decimal
    CPX #3
    BCS nc_ip_done
    INX
    LDA #'.'
    JSR send_byte
    JMP nc_ip_loop

.nc_ip_done
    ; Send comma and port
    LDA #','
    JSR send_byte

    LDA conn_port+1     ; High byte first for decimal
    LDX conn_port
    JSR send_word

    ; Send CR
    LDA #13
    JSR send_byte

    ; Wait for OK or CONNECT
    JSR wait_response
    BCS nc_fail

    LDA #NET_CONNECTED
    STA net_state
    CLC
    RTS

.nc_fail
    LDA #NET_DISCONNECTED
    STA net_state
    SEC
    RTS

.at_connect
    EQUS "AT+CIPSTART="
    EQUB 34
    EQUS "TCP"
    EQUB 34, ',', 34, 0

; -----------------------------------------------------------------------------
; Close connection
; -----------------------------------------------------------------------------
.net_close
    LDA #<at_close
    STA zp_ptr
    LDA #>at_close
    STA zp_ptr+1
    JSR send_string

    LDA #13
    JSR send_byte

    JSR wait_response

    LDA #NET_DISCONNECTED
    STA net_state
    RTS

.at_close   EQUS "AT+CIPCLOSE", 0

; -----------------------------------------------------------------------------
; Send data
; Input: tx_buffer contains 64 bytes
; Returns: C clear on success
; -----------------------------------------------------------------------------
.net_send
    LDA net_state
    CMP #NET_CONNECTED
    BNE ns_fail

    ; Send AT+CIPSEND=64
    LDA #<at_send
    STA zp_ptr
    LDA #>at_send
    STA zp_ptr+1
    JSR send_string
    LDA #13
    JSR send_byte

    ; Wait for > prompt
    JSR wait_prompt
    BCS ns_fail

    ; Send 64 bytes
    LDX #0
.ns_loop
    LDA tx_buffer,X
    JSR send_byte
    INX
    CPX #64
    BNE ns_loop

    ; Wait for SEND OK
    JSR wait_response
    RTS

.ns_fail
    SEC
    RTS

.at_send    EQUS "AT+CIPSEND=64", 0

; -----------------------------------------------------------------------------
; Receive data
; Output: rx_buffer contains data
; Returns: C clear if data received
; -----------------------------------------------------------------------------
.net_recv
    LDA net_state
    CMP #NET_CONNECTED
    BNE nr_fail

    ; Check for +IPD header
    JSR check_ipd
    BCS nr_fail

    ; Read 64 bytes
    LDX #0
.nr_loop
    JSR recv_byte_timeout
    BCS nr_partial
    STA rx_buffer,X
    INX
    CPX #64
    BNE nr_loop

    CLC
    RTS

.nr_partial
    ; Fill rest with zeros
    LDA #0
.nr_fill
    STA rx_buffer,X
    INX
    CPX #64
    BNE nr_fill
    SEC
    RTS

.nr_fail
    SEC
    RTS

; -----------------------------------------------------------------------------
; Low-level serial routines
; -----------------------------------------------------------------------------

; Send byte in A
.send_byte
    PHA
.sb_wait
    LDA ACIA_STATUS
    AND #ACIA_TDRE
    BEQ sb_wait
    PLA
    STA ACIA_TX
    RTS

; Receive byte with timeout
; Returns: A = byte, C set on timeout
.recv_byte_timeout
    LDX #0
    LDY #0
.rbt_loop
    LDA ACIA_STATUS
    AND #ACIA_RDRF
    BNE rbt_got
    DEX
    BNE rbt_loop
    DEY
    BNE rbt_loop
    SEC
    RTS
.rbt_got
    LDA ACIA_RX
    CLC
    RTS

; Send null-terminated string at zp_ptr
.send_string
    LDY #0
.ss_loop
    LDA (zp_ptr),Y
    BEQ ss_done
    JSR send_byte
    INY
    BNE ss_loop
.ss_done
    RTS

; Send decimal number in A
.send_decimal
    STA zp_temp3
    LDA #0
    STA zp_temp4        ; Leading zero flag

    ; Hundreds
    LDX #0
.sd_100
    LDA zp_temp3
    CMP #100
    BCC sd_tens
    SEC
    SBC #100
    STA zp_temp3
    INX
    JMP sd_100
.sd_tens
    TXA
    BEQ sd_no_100
    ORA #'0'
    JSR send_byte
    LDA #1
    STA zp_temp4
.sd_no_100
    ; Tens
    LDX #0
.sd_10
    LDA zp_temp3
    CMP #10
    BCC sd_units
    SEC
    SBC #10
    STA zp_temp3
    INX
    JMP sd_10
.sd_units
    TXA
    ORA zp_temp4
    BEQ sd_unit_only
    TXA
    ORA #'0'
    JSR send_byte
.sd_unit_only
    LDA zp_temp3
    ORA #'0'
    JSR send_byte
    RTS

; Send 16-bit word as decimal (A=high, X=low)
.send_word
    ; Simplified - just send low byte for ports < 256
    TXA
    JSR send_decimal
    RTS

; Send AT and wait for OK
.send_at
    LDA #'A'
    JSR send_byte
    LDA #'T'
    JSR send_byte
    LDA #13
    JSR send_byte
    JSR wait_response
    RTS

; Wait for OK/CONNECT response
.wait_response
    LDX #0              ; Timeout counter
.wr_loop
    JSR recv_byte_timeout
    BCS wr_timeout
    CMP #'O'            ; Looking for OK
    BEQ wr_maybe_ok
    CMP #'C'            ; Or CONNECT
    BEQ wr_ok
    JMP wr_loop
.wr_maybe_ok
    JSR recv_byte_timeout
    BCS wr_timeout
    CMP #'K'
    BEQ wr_ok
    JMP wr_loop
.wr_ok
    CLC
    RTS
.wr_timeout
    SEC
    RTS

; Wait for > prompt
.wait_prompt
    LDX #0
.wp_loop
    JSR recv_byte_timeout
    BCS wp_timeout
    CMP #'>'
    BEQ wp_ok
    INX
    BNE wp_loop
.wp_timeout
    SEC
    RTS
.wp_ok
    CLC
    RTS

; Check for +IPD: incoming data indicator
.check_ipd
    JSR recv_byte_timeout
    BCS ci_none
    CMP #'+'
    BNE ci_none
    JSR recv_byte_timeout
    BCS ci_none
    CMP #'I'
    BNE ci_none
    JSR recv_byte_timeout
    BCS ci_none
    CMP #'P'
    BNE ci_none
    JSR recv_byte_timeout
    BCS ci_none
    CMP #'D'
    BNE ci_none

    ; Skip to colon
.ci_skip
    JSR recv_byte_timeout
    BCS ci_none
    CMP #':'
    BNE ci_skip
    CLC
    RTS

.ci_none
    SEC
    RTS
