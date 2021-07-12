JankOs
======

Current features:
    mbr(legacy) bootloader
    io functions
    basic vga driver
    print_string function

Build from source:
    Firstly you need to be running linux or if you are in windows you can use wsl.
    2nd you need to clone the repo - git clone https://github.com/epicalex4444/JankOs.
    3rd you need to make sure you have all the nessesary commandline applications,
    these are applications listed with compilation next to them in tools/dependencies.txt.
    For x86_64-elf-gcc and x86_64-elf-gcc follow this installation guide https://wiki.osdev.org/GCC_Cross-Compiler.
    4th run the make command
    5th done you have compiled JankOs.iso, it is in the build directory

Contributing:
    Firstly build the repo from source to make sure everything is working.
    Then read the c and/or assembly style guides.
    Then just submit a pull request and wait for it to be accepted.

Running on real hardware:
    Get an iso either from the latest release or from builing from source.
    Read the Guest Os section in tools/dependencies.txt to find if your computer can run it.
    Then write the iso to a usb.
    Shutdown your pc and plug in the usb.
    Boot into bios and make sure legacy boot in enabled and then select the usb as the boot drive.

Writing to a usb with dd:
    have usb unplugged
    ls /dev/sd*
    this will list all your current drives
    plug in usb
    ls /dev/sd*
    there should be a new drive, use that drive for the next step
    dd if=JankOs.iso of=/dev/sdx
    /dev/sdx = your usb drive

Emulating in qemu:
    Get an iso either from the latest release or from builing from source.
    Download qemu if you don't have it.
    If made from source you can run make qemu.
    If not you can run qemu-system-x86_64 -drive file=JankOs.iso,format=raw --enable-kvm
