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
# program's virtual memory. Finally, the dynamic linker replaces all
# instances of the symbol in the program with the actual location of the
# symbol in the library.

.section .rodata
hello_msg:
.asciz "hello world\n" # Do we need null terminator for printf()?

.section .text
.globl _start
_start:
movq $hello_msg, %rdi # The first argument to printf().
call printf

movq $0, %rdi
call exit
