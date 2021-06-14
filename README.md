# JankOs
I don't know what I want to call the os but I definately want to change it.  
I am developing the os in my own time to learn about low level programming and hardware.  
I plan on turning this os into a development environment.  
I also plan on building a computer exclusively to run this os eventually.  

### design choices
cli  
no mouse  
basic filesystem  
basic networking  
gnu like tools built in  
be able to run user space code  
not maximally optised to save time  
multi threading capabilities  
64 bit  
1 user  
ring 0  

### software
It is going to have it's own bootloader, kernel and user space.  
For the bios I am using seabios for development but I want to have it work with most/all bios's.  
I will be using assembly(nasm) and c(gcc) for developing the os and qemu for emulating it.  
I am using vscode, make, and gdb to aid in development.  

### hardware
I will design the os around very specific hardware to save time.  
https://pcpartpicker.com/list/mcwkQD  

### documentation
doxygen is going to be used to generate pdf files.  
documentation in docs folder.  
