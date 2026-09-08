.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-64.s"

.section .rodata
file_name:
.asciz "test.dat"
read_err_msg:
.asciz "Failure when reading record\n"
.equ read_err_msg_len, (. - read_err_msg)

.section .bss
.lcomm record_buffer, RECORD_SIZE

.equ ST_ALLOC, REG_SIZE
.equ ST_INPUT_FD, -REG_SIZE

.section .text
.globl _start
_start:
movq %rsp, %rbp

subq $ST_ALLOC, %rsp

movl $0444, %edx # 3rd argument.
movl $0, %esi # 0 is O_RDONLY.
movq $file_name, %rdi
movl $SYS_OPEN, %eax
syscall

cmpl $0, %eax
jl exit_err

# Looks like we can store 32-bit value in 8 bytes allocation (?).
movl %eax, ST_INPUT_FD(%rbp)

movl $0, %r12d # Init max number.

record_read_begin:
movq $record_buffer, %rsi
movq ST_INPUT_FD(%rbp), %rdi
call read_record # read() syscall is the one who keep track of record position.

# If the read_record return value is not the same as RECORD_SIZE,
# it is either we got end of file (EOF) or error.
cmpl $RECORD_SIZE, %eax
jne record_read_end

movl (record_buffer + RECORD_AGE), %ebx
cmpl %ebx, %r12d
jge record_read_begin

movl %ebx, %r12d
jmp record_read_begin

record_read_end:
movl %eax, %ebx # Save the status code.

movq ST_INPUT_FD(%rbp), %rdi
movl $SYS_CLOSE, %eax
syscall

cmpl $0, %ebx
jl exit_read_err

cmpl $0, %eax # Check close() error.
jl exit_err

exit_normal:
movl %r12d, %edi
movl $SYS_EXIT, %eax
syscall

exit_read_err:
movl $read_err_msg_len, %edx
movq $read_err_msg, %rsi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall
movl %ebx, %eax
jmp exit_err

exit_err:
movl %eax, %edi
movl $SYS_EXIT, %eax
syscall

# %rdi: File descriptor.
# %rsi: Buffer address.
read_record:
pushq %rbp
movq %rsp, %rbp

movl $RECORD_SIZE, %edx # 3rd argument.
movl $SYS_READ, %eax # %rdi and %rsi already filled with necessary data.
syscall

movq %rbp, %rsp
popq %rbp
ret
