# Read record data from the file descriptor and put it into a buffer.

.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-32.s"

.equ ST_READ_BUFFER, REG_SIZE + REG_SIZE
.equ ST_FD, REG_SIZE + REG_SIZE + REG_SIZE

# Write the record data to the buffer and return a status code.
.section .text
.globl read_record
.type read_record, @function # Tell the linker that symbol read_record is a function.
read_record:
pushl %ebp
movl %esp, %ebp

# Is %ebx callee saved in x86 32-bit?
pushl %ebx

movl $RECORD_SIZE, %edx # 3rd argument.
movl ST_READ_BUFFER(%ebp), %ecx
movl ST_FD(%ebp), %ebx
movl $SYS_READ, %eax
int $LINUX_SYSCALL # read() return value is in %eax.

popl %ebx

movl %ebp, %esp
popl %ebp
ret
