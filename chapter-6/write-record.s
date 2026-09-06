# Write buffer data to the file descriptor.

.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-32.s"

.equ ST_WRITE_BUFFER, REG_SIZE + REG_SIZE
.equ ST_FD, REG_SIZE + REG_SIZE + REG_SIZE

# Write the buffer data to the file descriptor and return a status code.
.section .text
.globl write_record
.type write_record, @function # Tell the linker that symbol write_record is a function.
write_record:
pushl %ebp
movl %esp, %ebp

# Is %ebx callee saved in x86 32-bit?
pushl %ebx

movl $RECORD_SIZE, %edx # 3rd argument.
movl ST_WRITE_BUFFER(%ebp), %ecx
movl ST_FD(%ebp), %ebx
movl $SYS_WRITE, %eax
int $LINUX_SYSCALL # write() return value is in %eax.

popl %ebx

movl %ebp, %esp
popl %ebp
ret
