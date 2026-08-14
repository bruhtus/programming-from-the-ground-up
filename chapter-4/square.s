.section .text
.globl _start
_start:
pushl $5 # Square argument.
call square
addl $4, %esp # Deallocate previous argument (4 bytes).

movl $1, %eax
int $0x80

square:
pushl %ebp
movl %esp, %ebp

movl 8(%ebp), %ebx
imull 8(%ebp), %ebx # Square operation.

movl %ebp, %esp
popl %ebp
ret
