# Depends on:

.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-32.s"

.section .rodata
input_file_name:
.asciz "test.dat"

output_file_name:
.asciz "test_out.dat"

.section .bss
.lcomm record_buffer, RECORD_SIZE

.equ ST_INPUT_FD, -REG_SIZE
.equ ST_OUTPUT_FD, -(REG_SIZE + REG_SIZE)

.section .text
.globl _start
_start:
movl %esp, %ebp

subl $(REG_SIZE + REG_SIZE), %esp

movl $0666, %edx
movl $0, %ecx # O_RDONLY
movl $input_file_name, %ebx
movl $SYS_OPEN, %eax
int $LINUX_SYSCALL

movl %eax, ST_INPUT_FD(%ebp)

movl $0666, %edx
movl $0101, %ecx # 0101 is an octal number for O_CREAT (0100) and O_WRONLY (0001).
movl $output_file_name, %ebx
movl $SYS_OPEN, %eax
int $LINUX_SYSCALL

movl %eax, ST_OUTPUT_FD(%ebp)

loop_begin:
pushl ST_INPUT_FD(%ebp)
pushl $record_buffer
call read_record
addl $(REG_SIZE + REG_SIZE), %esp # Deallocate read_record() arguments.

cmpl $RECORD_SIZE, %eax
jne loop_end

# Currently we still didn't know how to write integer into the file.
incl (record_buffer + RECORD_AGE)

pushl ST_OUTPUT_FD(%ebp)
pushl $record_buffer
call write_record
addl $(REG_SIZE + REG_SIZE), %esp # Deallocate write_record() arguments.

jmp loop_begin

loop_end:
movl $SYS_EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL
