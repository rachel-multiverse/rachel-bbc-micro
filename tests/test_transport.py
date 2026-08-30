#!/usr/bin/env python3
"""Static regression checks for the physical BBC serial transport."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "src/net/wifi.asm").read_text()
def test_real_bbc_serial_path() -> None:
    assert "ACIA_CTRL       = $FE08" in SOURCE
    assert "OSBYTE 7: receive baud" in SOURCE
    assert "OSBYTE 8: transmit baud" in SOURCE
    assert 'EQUS "AT+CIPSTART="' in SOURCE
    assert 'EQUS ",6502"' in SOURCE
    assert 'EQUS "AT+CIPSEND=64"' in SOURCE
if __name__ == "__main__":
    test_real_bbc_serial_path()
    print("BBC transport checks passed")
