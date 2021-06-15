#removes built in rules and variables
MAKEFLAGS += -r -R

#diretories
BASE_DIR := $(shell pwd)
BOOT_DIR := $(BASE_DIR)/bootloader
BUILD_DIR := $(BASE_DIR)/build

#files
BOOT_BIN := $(BUILD_DIR)/boot.bin
BOOT_ASMS := $(wildcard $(BOOT_DIR)/*.asm)

#flags
NASM_FLAGS := -f bin
QEMU_FLAGS := -cpu Opteron_G5,+ibpb,+stibp,+virt-ssbd,+amd-ssbd,+amd-no-ssb,+pdpe1gb, -drive file=$(BOOT_BIN),format=raw -monitor stdio

#build with optimisation or debugging
RELEASE := false
ifeq ($(RELEASE),false)
	NASM_FLAGS += -g -w+all
else
	NASM_FLAGS += -Ox
endif

.PHONY: all clean run debug

all: $(BOOT_BIN)

clean:
	rm -f $(BUILD_DIR)/*

run:
	qemu-system-x86_64 $(QEMU_FLAGS)

debug:
	qemu-system-x86_64 $(QEMU_FLAGS) -s -S

$(BOOT_BIN): $(BOOT_ASMS) | $(BUILD_DIR)
	nasm $(NASM_FLAGS) $(BOOT_DIR)/boot.asm -o $@

$(BUILD_DIR):
	mkdir $@
