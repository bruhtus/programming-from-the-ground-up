.section .text
.globl _start
_start:
movl $0, %edi

call bad_example

movl $60, %eax
syscall

bad_example:
pushq %rbp
movq %rsp, %rbp

# Subtract 64-bit address by 32-bit value, which causing the 64-bit address
# to become 32-bit address and that can cause some problem when popping the
# value from the stack.
# This can be solved by using `subq $4, %rsp`.
subl $4, %esp

# Even when we put 64-bit value with movq, this will still cause problem with
# popping the value off the stack.
movl $4, -4(%rbp)

# The problem is that the stack pointer have been reduced to 32-bit address
# while pop and push need 64-bit address, which causing segfault (?).
popq %rax

movq %rbp, %rsp
popq %rbp
ret
