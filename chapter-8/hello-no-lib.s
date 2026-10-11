.include "common/linux-common.s"
.include "common/linux-x86-32.s"

.section .rodata
hello_msg:
.ascii "hello world\n"
.equ hello_msg_len, (. - hello_msg)

.section .text
.globl _start
_start:
movl $hello_msg_len, %edx
movl $hello_msg, %ecx
movl $STDOUT, %ebx
movl $SYS_WRITE, %eax
int $LINUX_SYSCALL

movl $0, %ebx
movl $SYS_EXIT, %eax
int $LINUX_SYSCALL
