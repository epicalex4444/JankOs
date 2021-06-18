#removes built in rules and variables
MAKEFLAGS += -r -R

#diretories
BASE_DIR := $(shell pwd)
BOOT_DIR := $(BASE_DIR)/bootloader
BUILD_DIR := $(BASE_DIR)/build

#files
BOOT_BIN := $(BUILD_DIR)/boot.bin
SPACE_BIN := $(BUILD_DIR)/extended_space.bin
OS_BIN := $(BUILD_DIR)/JankOs.bin
BOOT_ASMS := $(wildcard $(BOOT_DIR)/*.asm)

#flags
NASM_FLAGS := -f bin -I$(BOOT_DIR)
QEMU_FLAGS := -cpu Opteron_G5,+ibpb,+stibp,+virt-ssbd,+amd-ssbd,+amd-no-ssb,+pdpe1gb, -drive file=$(OS_BIN),format=raw -monitor stdio

#build with optimisation or debugging
RELEASE := false
ifeq ($(RELEASE),false)
	NASM_FLAGS += -g -w+all
else
	NASM_FLAGS += -Ox
endif

.PHONY: all clean run debug

all: $(OS_BIN)

clean:
	rm -f $(BUILD_DIR)/*

run: all
	qemu-system-x86_64 $(QEMU_FLAGS)

#opens qemu for gdb debugging
#TODO automatically connect gdb
gdb: all
	qemu-system-x86_64 $(QEMU_FLAGS) -s -S

$(OS_BIN): $(BOOT_BIN) $(SPACE_BIN) | $(BUILD_DIR)
	cat $^ > $@

$(BOOT_BIN): $(BOOT_ASMS)
	nasm $(NASM_FLAGS) $(BOOT_DIR)/boot.asm -o $@

$(SPACE_BIN): $(BOOT_ASMS)
	nasm $(NASM_FLAGS) $(BOOT_DIR)/extended_space.asm -o $@

$(BUILD_DIR):
	mkdir $@
