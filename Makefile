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
MBR_ASM := $(BOOT_DIR)/mbr.asm
VBR_ASM := $(BOOT_DIR)/vbr.asm
MBR_BIN := $(BUILD_DIR)/mbr.bin
VBR_BIN := $(BUILD_DIR)/vbr.bin
KERNEL_ENTRY_ASM := $(KERNEL_SRC_DIR)/kernel_entry.asm
KERNEL_ENTRY_OBJ := $(KERNEL_OBJ_DIR)/kernel_entry.o
KERNEL_SRCS := $(wildcard $(KERNEL_SRC_DIR)/*.c)
KERNEL_OBJS := $(subst src,obj,$(subst .c,.o,$(KERNEL_SRCS)))
KERNEL_DEPS := $(subst src,dep,$(subst .c,.d,$(KERNEL_SRCS)))
KERNEL_ELF := $(BUILD_DIR)/kernel.elf
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
FS_BIN := $(BUILD_DIR)/fs.bin
OS_ISO := $(BUILD_DIR)/JankOs.iso

#command options
CC := x86_64-elf-gcc
LD := x86_64-elf-ld
FS_COMPILER := ./tools/fs_compiler
NASM_FLAGS := 
QEMU_FLAGS := -drive file=$(OS_ISO),format=raw --enable-kvm
LD_FLAGS := -nostdlib -Tlink.ld -Ltools -lgcc
CC_FLAGS := -std=gnu18 -ffreestanding -mno-red-zone -nostdinc -masm=intel -I$(KERNEL_INC_DIR) -c

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
	rm -f $(KERNEL_ELF)
	rm -f $(BUILD_DIR)/*.bin
	rm -f $(KERNEL_OBJ_DIR)/*
	rm -f $(KERNEL_DEP_DIR)/*
	rm -rf $(DOCS_DIR)/*

qemu: all
	qemu-system-x86_64 $(QEMU_FLAGS)

doxygen: | $(DOCS_DIR)
	doxygen Doxyfile 1>/dev/null
	$(MAKE) -C $(DOCS_DIR)/latex 1>/dev/null 2>/dev/null

#tell make which headers are needed for which source files
#make will use the dependency file rule if it needs to
include $(KERNEL_DEPS)

$(MBR_BIN): $(MBR_ASM)
	nasm -f bin $(NASM_FLAGS) $< -o $@

$(VBR_BIN): $(VBR_ASM)
	nasm -f bin $(NASM_FLAGS) $< -o $@

$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_ASM)
	nasm -f elf64 $(NASM_FLAGS) $< -o $@

#rule for all kernel objects except kernel_entry.o
$(KERNEL_OBJ_DIR)/%.o: $(KERNEL_SRC_DIR)/%.c | $(KERNEL_OBJ_DIR)
	$(CC) $(CC_FLAGS) $^ -o $@

#rule for all kernel dependency files
$(KERNEL_DEP_DIR)/%.d: $(KERNEL_SRC_DIR)/%.c | $(KERNEL_DEP_DIR)
	$(CC) -I$(KERNEL_INC_DIR) -MM $^ -o $@

#linker respects order of files provided, KERNEL_ENTRY_OBJ has to be the first
$(KERNEL_ELF): $(KERNEL_ENTRY_OBJ) $(KERNEL_OBJS)
	$(LD) $(LD_FLAGS) $^ -o $@

$(KERNEL_BIN): $(KERNEL_ELF)
	objcopy -O binary $< $@

#lba = vbr sectors + 1
$(FS_BIN): $(KERNEL_BIN)
	$(FS_COMPILER) 5 $@ $<,kernel.bin

#combines bootloader and kernel
#then dynamically partitions
#adds partition id=0x19, sector 1-end, bootable
$(OS_ISO): $(MBR_BIN) $(VBR_BIN) $(FS_BIN)
	cat $^ > $@
	echo -e "n\np\n\n\n\nt\n19\na\nw\n" | fdisk $@ 1>/dev/null

$(KERNEL_OBJ_DIR) $(KERNEL_DEP_DIR) $(DOCS_DIR):
	mkdir $@
