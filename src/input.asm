; =============================================================================
; BBC MICRO INPUT MODULE
; =============================================================================

; -----------------------------------------------------------------------------
; Wait for key (blocking)
; Returns: A = key code
; -----------------------------------------------------------------------------
.wait_key
    JSR OSRDCH
    RTS

; -----------------------------------------------------------------------------
; Check for key (non-blocking)
; Returns: A = key if pressed, 0 if no key
; -----------------------------------------------------------------------------
.check_key
    LDA #$81            ; OSBYTE $81 - read key with timeout
    LDX #0              ; Timeout low
    LDY #0              ; Timeout high (immediate)
    JSR OSBYTE
    CPY #$FF            ; No key?
    BEQ ck_none
    TXA                 ; Key code in X
    RTS
.ck_none
    LDA #0
    RTS

; -----------------------------------------------------------------------------
; Input line
; Input: zp_ptr = buffer, X = max length
; Returns: A = length entered
; -----------------------------------------------------------------------------
.input_line
    STX zp_temp1        ; Max length
    LDY #0              ; Current position

.il_loop
    JSR wait_key

    CMP #KEY_RETURN
    BEQ il_done

    CMP #KEY_DELETE
    BEQ il_delete

    CPY zp_temp1
    BCS il_loop         ; At max

    CMP #32
    BCC il_loop         ; Non-printable
    CMP #127
    BCS il_loop

    STA (zp_ptr),Y
    INY
    JSR OSWRCH
    JMP il_loop

.il_delete
    CPY #0
    BEQ il_loop

    DEY
    LDA #KEY_DELETE
    JSR OSWRCH
    LDA #' '
    JSR OSWRCH
    LDA #KEY_DELETE
    JSR OSWRCH
    JMP il_loop

.il_done
    LDA #0
    STA (zp_ptr),Y
    TYA
    RTS
