.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-64.s"

.section .rodata
file_name:
.asciz "test.dat"
open_err_msg:
.asciz "Failed to open file\n"
.equ open_err_msg_len, (. - open_err_msg)
read_record_err_msg:
.asciz "Failed to read file\n"
.equ read_record_err_msg_len, (. - read_record_err_msg)
lseek_err_msg:
.asciz "lseek failed\n"
.equ lseek_err_msg_len, (. - lseek_err_msg)
write_record_err_msg:
.asciz "write record failed\n"
.equ write_record_err_msg_len, (. - write_record_err_msg)

.section .bss
.lcomm record_buffer, RECORD_SIZE

.section .text
.globl _start
_start:
movq %rsp, %rbp

movl $0644, %edx
movl $2, %esi # O_RDWR.
movq $file_name, %rdi
movl $SYS_OPEN, %eax
syscall

cmpl $0, %eax
jl exit_open_err

pushq %rax
.equ FD, REG_SIZE

loop_begin:
movl $RECORD_SIZE, %edx
movq $record_buffer, %rsi
movq -FD(%rbp), %rdi
movl $SYS_READ, %eax # It looks like the read() syscall reading 324 bytes at a time.
syscall

cmpl $0, %eax
jl prepare_read_record_err
je loop_end

# Increment age in current record.
incl (record_buffer + RECORD_AGE)

# Check /usr/include/unistd.h
movl $1, %edx # SEEK_SET (0), SEEK_CUR (1), SEEK_END (2).
movl $0, %esi
movq -FD(%rbp), %rdi
movl $SYS_LSEEK, %eax
syscall

cmpl $0, %eax
jl prepare_lseek_err

# Save the current read position.
movl %eax, %ebx

# Set position to the beginning of next record.
# Record bytes start from 0, so 0 - 323 is the first record and 324 - 647 is
# the second record.
subl $RECORD_SIZE, %eax

# Move write offset to the beginning of next record.
movl $0, %edx # SEEK_SET (0), SEEK_CUR (1), SEEK_END (2).
movl %eax, %esi
movq -FD(%rbp), %rdi
movl $SYS_LSEEK, %eax
syscall

cmpl $0, %eax
jl prepare_lseek_err

movl $RECORD_SIZE, %edx
movl $record_buffer, %esi
movq -FD(%rbp), %rdi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl prepare_write_record_err

# Restore to the last read position.
movl $0, %edx # SEEK_SET (0), SEEK_CUR (1), SEEK_END (2).
movl %ebx, %esi
movq -FD(%rbp), %rdi
movl $SYS_LSEEK, %eax
syscall

cmpl $0, %eax
jl prepare_lseek_err

jmp loop_begin

prepare_read_record_err:
movl %eax, %ebx

movl $read_record_err_msg_len, %edx
movq $read_record_err_msg, %rsi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

jmp loop_end_err

prepare_lseek_err:
movl %eax, %ebx

movl $lseek_err_msg_len, %edx
movq $lseek_err_msg, %rsi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

jmp loop_end_err

prepare_write_record_err:
movl %eax, %ebx

movl $write_record_err_msg_len, %edx
movq $write_record_err_msg, %rsi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

jmp loop_end_err

loop_end_err:
movl -FD(%rbp), %edi
movl $SYS_CLOSE, %eax
syscall

jmp exit_err

loop_end:
movl -FD(%rbp), %edi
movl $SYS_CLOSE, %eax
syscall

jmp exit_normal

exit_normal:
movl $0, %edi
movl $SYS_EXIT, %eax
syscall

exit_open_err:
movl %eax, %ebx

movl $open_err_msg_len, %edx
movq $open_err_msg, %rsi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

jmp exit_err

exit_err:
movl %ebx, %edi
movl $SYS_EXIT, %eax
syscall
