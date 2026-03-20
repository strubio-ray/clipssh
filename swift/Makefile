.PHONY: build clean

BUILD_DIR ?= ../build

build: $(BUILD_DIR)/clipssh-paste

$(BUILD_DIR)/clipssh-paste: ClipsshPaste.swift
	@mkdir -p $(BUILD_DIR)
	swiftc -O -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
