# This example is to remove newline character at the end of file when editor,
# such as vim with `fixendofline` option, suddenly add newline character at the
# end of file.

.include "common/linux-x86-64.s"

.section .rodata
file_name:
.asciz "anu.dat"
.equ file_name_len, (. - file_name)
data:
.asciz "anu"
.equ data_len, (. - data)

.section .bss
.lcomm check_char, 1

.section .text
.globl _start
_start:
movq %rsp, %rbp

subq $16, %rsp

movl $0644, %edx
movl $0102, %esi # O_CREAT, O_RDWR.
movq $file_name, %rdi
movl $SYS_OPEN, %eax
syscall

.equ FD, 8
movl %eax, -FD(%rbp)

movl $2, %edx # SEEK_SET (0), SEEK_CUR (1), SEEK_END (2).
movl $0, %esi
movl -FD(%rbp), %edi
movl $SYS_LSEEK, %eax
syscall

cmpl $0, %eax # Means this is a new file.
je write_data

decl %eax
movl %eax, -16(%rbp)

movl $0, %edx # SEEK_SET (0), SEEK_CUR (1), SEEK_END (2).
movl %eax, %esi
movq -FD(%rbp), %rdi
movl $SYS_LSEEK, %eax
syscall

movl $1, %edx
movq $check_char, %rsi
movl -FD(%rbp), %edi
movl $SYS_READ, %eax
syscall

cmpl $10, check_char
jne write_data

movl $0, %edx # SEEK_SET (0), SEEK_CUR (1), SEEK_END (2).
movl -16(%rbp), %esi
movq -FD(%rbp), %rdi
movl $SYS_LSEEK, %eax
syscall

write_data:
movl $data_len, %edx
movl $data, %esi
movq -FD(%rbp), %rdi
movl $SYS_WRITE, %eax
syscall

movl $0, %edi
movl $SYS_EXIT, %eax
syscall
