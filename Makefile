#removes built in rules and variables
MAKEFLAGS += -r -R

#diretories
BOOT_DIR := bootloader
BUILD_DIR := build
KERNEL_DIR := kernel
DOCS_DIR := docs
KERNEL_SRC_DIR := $(KERNEL_DIR)/src
KERNEL_INC_DIR := $(KERNEL_DIR)/inc
KERNEL_OBJ_DIR := $(KERNEL_DIR)/obj
KERNEL_DEP_DIR := $(KERNEL_DIR)/dep

#files
BOOT_BIN := $(BUILD_DIR)/boot.bin
BOOT_ASM := $(BOOT_DIR)/boot.asm
BOOT_ASMS := $(wildcard $(BOOT_DIR)/*.asm)
KERNEL_ENTRY_ASM := $(KERNEL_SRC_DIR)/kernel_entry.asm
KERNEL_ENTRY_OBJ := $(KERNEL_OBJ_DIR)/kernel_entry.o
KERNEL_SRCS := $(wildcard $(KERNEL_SRC_DIR)/*.c)
KERNEL_OBJS := $(subst src,obj,$(subst .c,.o,$(KERNEL_SRCS)))
KERNEL_DEPS := $(subst src,dep,$(subst .c,.d,$(KERNEL_SRCS)))
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
OS_ISO := $(BUILD_DIR)/JankOs.iso

#command options
CC := x86_64-elf-gcc
LD := x86_64-elf-ld
NASM_FLAGS := 
QEMU_FLAGS := -drive file=$(OS_ISO),format=raw
LD_FLAGS := -nostdlib -Tlink.ld -L$(BUILD_DIR) -lgcc
CC_FLAGS := -std=gnu18 -ffreestanding -mno-red-zone -nostdinc -I$(KERNEL_INC_DIR) -c

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

.PHONY: all clean qemu doxygen

all: $(OS_ISO)

clean:
	rm -f $(OS_ISO)
	rm -f $(BUILD_DIR)/*.bin
	rm -f $(KERNEL_OBJ_DIR)/*
	rm -f $(KERNEL_DEP_DIR)/*
	rm -rf $(DOCS_DIR)/*

qemu: all
	qemu-system-x86_64 $(QEMU_FLAGS)

doxygen: all | $(DOCS_DIR)
	doxygen Doxyfile 1>/dev/null
	$(MAKE) -C $(DOCS_DIR)/latex 1>/dev/null 2>/dev/null

#tell make which headers are needed for which source files
#make will use the dependency file rule if it needs to
include $(KERNEL_DEPS)

$(BOOT_BIN): $(BOOT_ASMS)
	nasm -f bin -I$(BOOT_DIR) $(NASM_FLAGS) $(BOOT_ASM) -o $@

$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_ASM)
	nasm -f elf64 $(NASM_FLAGS) $< -o $@

#rule for all kernel objects except kernel_entry.o
$(KERNEL_OBJ_DIR)/%.o: $(KERNEL_SRC_DIR)/%.c | $(KERNEL_OBJ_DIR)
	$(CC) $(CC_FLAGS) $^ -o $@

#rule for all kernel dependency files
$(KERNEL_DEP_DIR)/%.d: $(KERNEL_SRC_DIR)/%.c | $(KERNEL_DEP_DIR)
	$(CC) -I$(KERNEL_INC_DIR) -MM $^ -o $@

#linker respects order of files provided, KERNEL_ENTRY_OBJ has to be the first
$(KERNEL_BIN): $(KERNEL_ENTRY_OBJ) $(KERNEL_OBJS)
	$(LD) $(LD_FLAGS) $^ -o $@

#combines bootloader and kernel
#then dynamically partitions
#adds partition id=0x19, sector 1-end, bootable
$(OS_ISO): $(BOOT_BIN) $(KERNEL_BIN)
	cat $^ > $@
	echo -e "n\np\n\n\n\nt\n19\na\nw\n" | fdisk $@ 1>/dev/null

$(KERNEL_OBJ_DIR) $(KERNEL_DEP_DIR) $(DOCS_DIR):
	mkdir $@
