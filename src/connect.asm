; =============================================================================
; BBC MICRO CONNECTION MODULE
; =============================================================================

; -----------------------------------------------------------------------------
; Connect to game server
; Input: zp_ptr = hostname string, X = port low, Y = port high
; Returns: C set on error
; -----------------------------------------------------------------------------
.connect_server
    STX conn_port
    STY conn_port+1

    ; Initialize network
    JSR net_init
    BCS conn_fail

    ; Resolve hostname (simplified - assume IP in string)
    JSR parse_ip
    BCS conn_fail

    ; Open TCP connection
    JSR net_connect
    BCS conn_fail

    ; Connection established
    LDA #1
    STA connected
    CLC
    RTS

.conn_fail
    LDA #0
    STA connected
    SEC
    RTS

.conn_port      EQUW 0
.connected      EQUB 0

; -----------------------------------------------------------------------------
; Disconnect from server
; -----------------------------------------------------------------------------
.disconnect
    LDA connected
    BEQ disc_done

    JSR net_close
    LDA #0
    STA connected

.disc_done
    RTS

; -----------------------------------------------------------------------------
; Parse IP address from string
; Input: zp_ptr = string "n.n.n.n"
; Output: server_ip filled
; -----------------------------------------------------------------------------
.parse_ip
    LDY #0
    LDX #0              ; IP byte index

.pi_byte
    LDA #0
    STA zp_temp1        ; Accumulator for current byte

.pi_digit
    LDA (zp_ptr),Y
    BEQ pi_end_byte
    CMP #'.'
    BEQ pi_next_byte
    CMP #'0'
    BCC pi_error
    CMP #':'
    BCS pi_check_end

    ; Digit 0-9
    SEC
    SBC #'0'
    STA zp_temp2

    ; Multiply accumulator by 10
    LDA zp_temp1
    ASL A
    ASL A
    ADC zp_temp1
    ASL A
    ADC zp_temp2
    STA zp_temp1

    INY
    JMP pi_digit

.pi_check_end
    CMP #':'
    BEQ pi_end_byte
    JMP pi_error

.pi_next_byte
    LDA zp_temp1
    STA server_ip,X
    INX
    INY
    CPX #4
    BCC pi_byte
    JMP pi_error

.pi_end_byte
    LDA zp_temp1
    STA server_ip,X
    INX
    CPX #4
    BNE pi_need_more
    CLC
    RTS

.pi_need_more
    ; Fill remaining with zeros
    LDA #0
.pi_fill
    STA server_ip,X
    INX
    CPX #4
    BCC pi_fill
    CLC
    RTS

.pi_error
    SEC
    RTS

.server_ip      EQUD 0

; -----------------------------------------------------------------------------
; Show connection screen
; -----------------------------------------------------------------------------
.show_connect_screen
    JSR display_init

    LDX #10
    LDY #8
    JSR set_cursor
    LDA #<cs_title
    STA zp_ptr
    LDA #>cs_title
    STA zp_ptr+1
    JSR print_string

    LDX #8
    LDY #10
    JSR set_cursor
    LDA #<cs_prompt
    STA zp_ptr
    LDA #>cs_prompt
    STA zp_ptr+1
    JSR print_string

    LDX #8
    LDY #12
    JSR set_cursor

    RTS

.cs_title   EQUS "CONNECT TO RACHEL", 0
.cs_prompt  EQUS "SERVER IP: ", 0

; -----------------------------------------------------------------------------
; Get server address from user
; Returns: C set if cancelled
; -----------------------------------------------------------------------------
.get_server_address
    JSR show_connect_screen

    ; Input IP address
    LDA #<input_buffer
    STA zp_ptr
    LDA #>input_buffer
    STA zp_ptr+1
    LDX #15
    JSR input_line

    CMP #0
    BEQ gsa_cancel

    ; Parse and store
    LDA #<input_buffer
    STA zp_ptr
    LDA #>input_buffer
    STA zp_ptr+1
    JSR parse_ip
    BCS gsa_cancel

    CLC
    RTS

.gsa_cancel
    SEC
    RTS

.input_buffer   EQUS "               ", 0

; -----------------------------------------------------------------------------
; Show connecting message
; -----------------------------------------------------------------------------
.show_connecting
    LDX #10
    LDY #14
    JSR set_cursor
    LDA #<sc_msg
    STA zp_ptr
    LDA #>sc_msg
    STA zp_ptr+1
    JSR print_string
    RTS

.sc_msg EQUS "CONNECTING...", 0

; -----------------------------------------------------------------------------
; Show connection error
; -----------------------------------------------------------------------------
.show_connect_error
    LDX #8
    LDY #14
    JSR set_cursor
    LDA #<sce_msg
    STA zp_ptr
    LDA #>sce_msg
    STA zp_ptr+1
    JSR print_string
    JSR wait_key
    RTS

.sce_msg    EQUS "CONNECTION FAILED!", 0
