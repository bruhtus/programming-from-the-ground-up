# Depends on:
# - chapter-6/read-record.s
# - chapter-6/count-chars.s
# - chapter-6/write-newline.s
# - simple-memory-manager.s

.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-32.s"

.section .rodata
file_name:
.asciz "test.dat"

.section .data
record_buffer_ptr:
.long 0

.equ ST_FD, REG_SIZE + REG_SIZE
.equ ST_INPUT_FD, -REG_SIZE
.equ ST_OUTPUT_FD, -(REG_SIZE + REG_SIZE)

.section .text
.globl _start
_start:
movl %esp, %ebp

subl $ST_FD, %esp

movl $0444, %edx # 3rd argument.
movl $0, %ecx # 0 is for O_RDONLY.
movl $file_name, %ebx
movl $SYS_OPEN, %eax
int $LINUX_SYSCALL

movl %eax, ST_INPUT_FD(%ebp)
movl $STDOUT, ST_OUTPUT_FD(%ebp)

call allocate_init

pushl $RECORD_SIZE
call allocate

cmpl $0, %eax # allocate() return 0 on failure.
je record_exit

movl %eax, record_buffer_ptr

record_read_loop:
pushl ST_INPUT_FD(%ebp)
pushl record_buffer_ptr
call read_record

addl $(REG_SIZE + REG_SIZE), %esp # Deallocate space read_record arguments.

# If the read_record return value is not the same as RECORD_SIZE,
# it is either we got end of file (EOF) or error.
cmpl $RECORD_SIZE, %eax
jne record_read_end

movl record_buffer_ptr, %eax
addl $RECORD_FIRST_NAME, %eax
pushl %eax
call count_chars

addl $REG_SIZE, %esp # Deallocate space after finishing with function arguments.

movl %eax, %edx # 3rd argument.
movl record_buffer_ptr, %ecx
addl $RECORD_FIRST_NAME, %ecx
movl ST_OUTPUT_FD(%ebp), %ebx
movl $SYS_WRITE, %eax
int $LINUX_SYSCALL

pushl ST_OUTPUT_FD(%ebp)
call write_newline

addl $REG_SIZE, %esp # Deallocate space after finishing with function arguments.

jmp record_read_loop

record_read_end:
pushl record_buffer_ptr
call deallocate

record_exit:
movl $0, %ebx
movl $SYS_EXIT, %eax
int $LINUX_SYSCALL
