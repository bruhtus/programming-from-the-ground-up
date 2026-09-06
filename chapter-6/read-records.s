# Depends on:
# - read-record.s
# - count-chars.s
# - write-newline.s

.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-32.s"

.section .rodata
file_name:
.asciz "test.dat"

.section .bss
.lcomm record_buffer, RECORD_SIZE

.equ ST_FD, REG_SIZE + REG_SIZE
.equ ST_INPUT_FD, -REG_SIZE
.equ ST_OUTPUT_FD, -(REG_SIZE + REG_SIZE)

.section .text
.globl _start
_start:
movl %esp, %ebp

subl $ST_FD, %esp # Allocate space to hold input and output file descriptors.

movl $0444, %edx # 3rd argument.
movl $0, %ecx # 0 is for O_RDONLY.
movl $file_name, %ebx
movl $SYS_OPEN, %eax
int $LINUX_SYSCALL

movl %eax, ST_INPUT_FD(%ebp)

# So that we change the output file descriptor easily.
movl $STDOUT, ST_OUTPUT_FD(%ebp)

record_read_loop:
pushl ST_INPUT_FD(%ebp)
pushl $record_buffer
call read_record

addl $(REG_SIZE + REG_SIZE), %esp # Deallocate space read_record arguments.

# If the read_record return value is not the same as RECORD_SIZE,
# it is either we got end of file (EOF) or error.
cmpl $RECORD_SIZE, %eax
jne record_read_end

pushl $(RECORD_FIRST_NAME + record_buffer) # Looks like we can add multiple constants?
call count_chars

addl $REG_SIZE, %esp # Deallocate space after finishing with function arguments.

movl %eax, %edx # 3rd argument.
movl $(RECORD_FIRST_NAME + record_buffer), %ecx
movl ST_OUTPUT_FD(%ebp), %ebx
movl $SYS_WRITE, %eax
int $LINUX_SYSCALL

pushl ST_OUTPUT_FD(%ebp)
call write_newline

addl $REG_SIZE, %esp # Deallocate space after finishing with function arguments.

jmp record_read_loop

record_read_end:
movl $0, %ebx
movl $SYS_EXIT, %eax
int $LINUX_SYSCALL
