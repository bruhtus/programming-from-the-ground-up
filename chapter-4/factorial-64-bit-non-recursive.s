.section .text
.globl _start
_start:
leaq (%rsp), %rbx # Put the current stack pointer for clean up.

pushq $5
call factorial
leaq (%rbx), %rsp # Deallocate previous argument.

movl $60, %eax
syscall

factorial:
pushq %rbp
movq %rsp, %rbp

movl 16(%rbp), %edi # Try using 32-bit value instead of 64-bit value.

cmpl $0, %edi
je factorial_zero

movl %edi, %eax

factorial_loop:
cmpl $1, %eax
je factorial_exit
decl %eax
imull %eax, %edi
jmp factorial_loop

factorial_zero:
movl $1, %edi

factorial_exit:
movq %rbp, %rsp
popq %rbp
ret
