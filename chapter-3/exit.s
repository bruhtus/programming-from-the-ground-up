.section .text
.globl _start # This is for linux kernel, linux kernel start execution from _start.
_start:
movl $1, %eax # Number 1 in %eax means exit() system call on linux.
movl $69, %ebx # %ebx value is the status code for exit() system call.
int $0x80 # Interrupt program with "terminate" instruction.
