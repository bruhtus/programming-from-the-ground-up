.section .text
.globl _start
_start:
pushq $5 # Square argument.
call square
addq $8, %rsp # Deallocate previous argument (8 bytes).

movl $60, %eax
syscall

square:
pushq %rbp
movq %rsp, %rbp

movl 16(%rbp), %edi
imull 16(%rbp), %edi # Square operation.

movq %rbp, %rsp
popq %rbp
ret
