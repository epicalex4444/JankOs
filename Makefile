#removes built in rules and variables
MAKEFLAGS += -r -R

#diretories
BOOT_DIR := bootloader
BUILD_DIR := build

#files
BOOT_BIN := $(BUILD_DIR)/boot.bin
BOOT_OBJ := $(BUILD_DIR)/boot.o
SPACE_BIN := $(BUILD_DIR)/extended_space.bin
OS_BIN := $(BUILD_DIR)/JankOs.bin
BOOT_ASMS := $(wildcard $(BOOT_DIR)/*.asm)

#command options
NASM_FLAGS := -f bin -I$(BOOT_DIR)

QEMU_FLAGS := -drive file=$(BOOT_BIN),format=raw -monitor stdio

#build with optimisation or debugging
RELEASE := false
ifeq ($(RELEASE),false)
	NASM_FLAGS += -g -w+all
else
	NASM_FLAGS += -Ox
	LDFLAGS += -O2
endif

.PHONY: all clean qemu

all: $(BOOT_BIN)

clean:
	rm -f $(BUILD_DIR)/*

qemu: all
	qemu-system-x86_64 $(QEMU_FLAGS)

$(BOOT_BIN): $(BOOT_ASMS)  | $(BUILD_DIR)
	nasm $(NASM_FLAGS) $(BOOT_DIR)/boot.asm -o $@

$(BUILD_DIR):
	mkdir $@
