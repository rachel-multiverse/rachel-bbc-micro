# Rachel BBC Micro Client Makefile

BEEBASM ?= /tmp/beebasm-src/beebasm

BUILD_DIR = build
SRC_DIR = src

TARGET = $(BUILD_DIR)/rachel.ssd

.PHONY: all clean

all: $(BUILD_DIR) $(TARGET)
	@echo "Built: $(TARGET)"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SRC_DIR)/main.asm $(SRC_DIR)/*.asm $(SRC_DIR)/net/*.asm
	cd $(SRC_DIR) && $(BEEBASM) -i main.asm -do ../$(TARGET) -boot RACHEL

clean:
	rm -rf $(BUILD_DIR)
