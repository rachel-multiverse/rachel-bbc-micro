# Rachel BBC Micro Client

Network client for the Rachel card game, connecting to the cross-platform host
through a serial WiFi adapter.

## Requirements

- BBC Micro Model B, B+, or Master
- BBC Micro Model B/B+/Master RS423 port
- ESP-AT serial WiFi adapter with an appropriate RS423/TTL level interface
- [BeebAsm](https://github.com/stardot/beebasm) 6502 assembler

## Building

```bash
# Build
make

# Output: build/rachel.ssd (disc image)
```

## Hardware Setup

The implemented transport is the BBC's real 6850 ACIA/Serial ULA at 9600 baud,
driving an ESP-AT adapter with `CIPSTART`, `CIPSEND`, and `+IPD`. PiTubeDirect
and Econet are useful future transports, but are not implemented by this build.

## Network Configuration

On startup, enter the host address in the format:
```
SERVER IP (PORT 8765): 192.168.1.100
```

## Architecture

The cross-platform host runs the game engine and sends display state via RUBP. The BBC Micro:

1. Connects to host via TCP/IP
2. Receives game state updates (64-byte RUBP messages)
3. Renders the game display (Mode 7: 40x25 teletext)
4. Sends player input back to host

## File Structure

```
src/
  main.asm       - Entry point, main loop
  display.asm    - Mode 7 text output routines
  input.asm      - Keyboard handling via OSBYTE
  game.asm       - Game screen rendering
  connect.asm    - Connection UI
  rubp.asm       - RUBP protocol encoding/decoding
  net/
    wifi.asm     - WiFi/network driver
```

## Protocol

Uses RUBP (Rachel Unified Binary Protocol) - 64-byte fixed messages with 16-byte header and 48-byte payload. Full specification: [rachel-multiverse/protocol](https://github.com/rachel-multiverse/protocol).

## Related Projects

- [rachel-ios](https://github.com/rachel-multiverse/rachel-ios) - iOS host application
- [rachel-apple2](https://github.com/rachel-multiverse/rachel-apple2) - Apple II client
- [rachel-c64](https://github.com/rachel-multiverse/rachel-c64) - Commodore 64 client
