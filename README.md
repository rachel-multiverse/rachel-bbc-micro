# Rachel BBC Micro Client

Render-only client for the Rachel card game, connecting to an iOS host via WiFi adapter or Econet bridge.

## Requirements

- BBC Micro Model B, B+, or Master
- PiTubeDirect with network support, or WiFi adapter
- [BeebAsm](https://github.com/stardot/beebasm) 6502 assembler

## Building

```bash
# Build
make

# Output: build/rachel.ssd (disc image)
```

## Hardware Setup

The client supports multiple networking options:
- **PiTubeDirect** with TCP/IP stack
- **WiFi adapter** with AT command interface
- **Econet bridge** to TCP/IP gateway

## Network Configuration

On startup, enter the host address in the format:
```
HOST:PORT> 192.168.1.100:6502
```

## Architecture

This is a **render-only client** - the iOS host runs the game engine and sends display state via the RUBP binary protocol. The BBC Micro:

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

Uses RUBP (Rachel Unified Binary Protocol) - 64-byte fixed messages with 16-byte header and 48-byte payload. See `docs/PROTOCOL.md` in the main Rachel repository.

## Related Projects

- [rachel-ios](https://github.com/rachel-multiverse/rachel-ios) - iOS host application
- [rachel-apple2](https://github.com/rachel-multiverse/rachel-apple2) - Apple II client
- [rachel-c64](https://github.com/rachel-multiverse/rachel-c64) - Commodore 64 client
