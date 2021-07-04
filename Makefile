#removes built in rules and variables
MAKEFLAGS += -r -R

#diretories
BOOT_DIR := bootloader
BUILD_DIR := build
KERNEL_DIR := kernel
KERNEL_SRC_DIR := $(KERNEL_DIR)/src
KERNEL_INC_DIR := $(KERNEL_DIR)/inc
KERNEL_OBJ_DIR := $(KERNEL_DIR)/obj
KERNEL_DEP_DIR := $(KERNEL_DIR)/dep

#files
BOOT_BIN := $(BUILD_DIR)/boot.bin
BOOT_ASMS := $(wildcard $(BOOT_DIR)/*.asm)

#command options
NASM_FLAGS := -f bin -I$(BOOT_DIR)
QEMU_FLAGS := -drive file=build/JankOs.bin,format=raw
LD_FLAGS := -nostdlib -T link.ld
CC_FLAGS := -std=gnu18 -m64 -ffreestanding -nostdinc -I$(KERNEL_INC_DIR) -c 

#build with optimisation or debugging
RELEASE := false
ifeq ($(RELEASE),false)
	NASM_FLAGS += -g -w+all
	QEMU_FLAGS += -monitor stdio
	CC_FLAGS += -g -Wpedantic -Wall -Wextra
else
	NASM_FLAGS += -Ox
	LD_FLAGS += -O2
	CC_FLAGS += -O2
endif

.PHONY: all clean qemu

all: build/JankOs.bin

clean:
	rm -f $(BUILD_DIR)/*
	rm -f kernel/obj/*
	rm -f kernel/dep/*

qemu: all
	qemu-system-x86_64 $(QEMU_FLAGS)

$(BOOT_BIN): $(BOOT_ASMS) | $(BUILD_DIR)
	nasm $(NASM_FLAGS) $(BOOT_DIR)/boot.asm -o $@

kernel/obj/main.o: kernel/src/main.c
	gcc $(CC_FLAGS) $^ -o $@

build/kernel.bin: kernel/obj/main.o
	ld $(LD_FLAGS) $^ -o $@

build/JankOs.bin: $(BOOT_BIN) build/kernel.bin
	cat $^ > $@

$(BUILD_DIR):
	mkdir $@
