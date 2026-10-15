# My machine only has /lib/ld-linux-x86-64.so.2, so assembling this in x86-64 format.
# We need `--dynamic-linker /lib/ld-linux-x86-64.so.2` and `-lc` (which I assume link
# C library or libc?) with `ld` command, like this:
# ld -o chapter-8/hello-lib --dynamic-linker /lib/ld-linux-x86-64.so.2 -lc \
# chapter-8/hello-lib.o
#
# When the program begins, the kernel will load the dynamic linker first
# (in this case `/lib/ld-linux-x86-64.so.2`). This dynamic linker looks at
# the program and sees that it needs the C library to run, so the dynamic
# linker search for a file called libc.so in the standard places (listed
# in /etc/ld.so.conf and LD_LIBRARY_PATH env variable). After the dynamic
# linker found all the needed symbol, it then loads the library into the
# program virtual memory. Finally, the dynamic linker replaces all
# instances of the symbol in the program with the actual location of the
# symbol in the library.
#
# To use x86 (32-bit) dynamic linker on arch linux, we can download package
# lib32-glibc.

.section .rodata
message_format:
.asciz "hello %s %d %d %d %d %d %s %d\n" # Do we need null terminator for printf()?
first_arg:
.asciz "world"
second_arg:
.long 69
third_arg:
.long 42
fourth_arg:
.long 6942
fifth_arg:
.long 4269
sixth_arg:
.long 69420
seventh_arg:
.asciz "yeah"
eigth_arg:
.long 67

.section .text
.globl _start
_start:
movq %rsp, %rbp

subq $16, %rsp
subq $16, %rsp

# Looks like we need to align the stack to 16 byte before executing printf(),
# even though we did not use all the available stack allocation (?).
#
# References:
# - https://linuxvox.com/blog/calling-printf-in-x86-64-using-gnu-assembler/
# - https://blog.nelhage.com/2010/10/amd64-and-va_arg/
movl eigth_arg, %r9d # To mitigate x86 limitation that can not move between memory address.
movl %r9d, -16(%rbp)
movq $seventh_arg, -24(%rbp)
movl sixth_arg, %r9d
movl %r9d, -32(%rbp) # Function will look at the top of stack as seventh argument and continue from there.
movl fifth_arg, %r9d
movl fourth_arg, %r8d
movl third_arg, %ecx
movl second_arg, %edx
movq $first_arg, %rsi
movq $message_format, %rdi # The first argument to printf().
call printf

# Deallocate stack space.
addq $16, %rsp
addq $16, %rsp

movq $0, %rdi
call exit
