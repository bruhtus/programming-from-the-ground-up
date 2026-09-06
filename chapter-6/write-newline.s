.include "common/linux-common.s"
.include "common/linux-x86-32.s"

.section .rodata
newline:
.ascii "\n"

.equ ST_FD, REG_SIZE + REG_SIZE

.section .text
.globl write_newline
.type write_newline, @function
write_newline:
pushl %ebp
movl %esp, %ebp

movl $1, %edx
movl $newline, %ecx # Address for newline character.
movl ST_FD(%ebp), %ebx
movl $SYS_WRITE, %eax
int $LINUX_SYSCALL

movl %ebp, %esp
popl %ebp
ret
