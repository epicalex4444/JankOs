#removes built in rules and variables
MAKEFLAGS += -r -R

#diretories
BASE_DIR := $(shell pwd)
BOOT_DIR := $(BASE_DIR)/bootloader
BUILD_DIR := $(BASE_DIR)/build

#files
BOOT_BIN := $(BUILD_DIR)/boot.bin
BOOT_OBJ := $(BUILD_DIR)/boot.o
SPACE_BIN := $(BUILD_DIR)/extended_space.bin
OS_BIN := $(BUILD_DIR)/JankOs.bin
BOOT_ASMS := $(wildcard $(BOOT_DIR)/*.asm)

#command options
NASM_FLAGS := -f elf64 -I$(BOOT_DIR)

QEMU_FLAGS := -cpu Opteron_G5,+ibpb,+stibp,+virt-ssbd,+amd-ssbd,+amd-no-ssb,+pdpe1gb, -drive file=$(BOOT_BIN),format=raw -monitor stdio

LD := x86_64-elf-ld
LDFLAGS := -nostdlib -T link.ld

#build with optimisation or debugging
RELEASE := false
ifeq ($(RELEASE),false)
	NASM_FLAGS += -g -w+all
else
	NASM_FLAGS += -Ox
	LDFLAGS += -O2
endif

.PHONY: all clean run debug

all: $(BOOT_BIN)

clean:
	rm -f $(BUILD_DIR)/*

run: all
	qemu-system-x86_64 $(QEMU_FLAGS)

#opens qemu for gdb debugging
#TODO automatically connect gdb
gdb: all
	qemu-system-x86_64 $(QEMU_FLAGS) -s -S

$(BOOT_OBJ): $(BOOT_ASMS) | $(BUILD_DIR)
	nasm $(NASM_FLAGS) $(BOOT_DIR)/boot.asm -o $@

$(BOOT_BIN): $(BOOT_OBJ)
	$(LD) $(LDFLAGS) $^ -o $@

$(BUILD_DIR):
	mkdir $@
