.equ SYS_CLOSE, 3
.equ SYS_OPEN, 2
.equ SYS_WRITE, 1
.equ SYS_READ, 0
.equ SYS_EXIT, 60

.equ O_CREAT_WRONLY_TRUNC, 01101 # Using octal number.
.equ REG_SIZE, 8 # 8 bytes (1 byte = 8 bits, 8 bytes = 64 bits).

# References:
# - https://stackoverflow.com/a/59293759
# - https://sourceware.org/binutils/docs-2.31/as/String.html#String
.section .rodata
message:
.string "Some message!"
# The current address in section .rodata - the first address from message label.
# Reference: https://stackoverflow.com/a/63928977
.equ message_len, (. - message - 1) # For some reason, the calculated length has 1 more character?
output_filename:
.string "some-file.txt"

.section .text
.globl _start
_start:
movq %rsp, %rbp

subq $REG_SIZE, %rsp # Allocate for output file descriptor.

open_fd:
movl $0644, %edx # 3rd argument.
movl $O_CREAT_WRONLY_TRUNC, %esi
movq $output_filename, %rdi # Use the first character address of file name.
movl $SYS_OPEN, %eax
syscall

movq %rax, -REG_SIZE(%rbp)

movl $message_len, %edx
movq $message, %rsi
movq -REG_SIZE(%rbp), %rdi # Put output file descriptor.
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl exit_write_err # Exit if write() failed (signed).

close_fd:
movq -REG_SIZE(%rbp), %rdi
movl $SYS_CLOSE, %eax
syscall

exit_normal:
movl $0, %edi
movl $SYS_EXIT, %eax
syscall

exit_write_err:
movl $69, %r12d
jmp exit_err

exit_err:
movl %r12d, %edi
movl $SYS_EXIT, %eax
syscall
