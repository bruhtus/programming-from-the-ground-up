.section .text
.globl _start
_start:
pushq $4
call factorial
addq $8, %rsp

movl %eax, %edi

movl $60, %eax
syscall

factorial:
pushq %rbp
movq %rsp, %rbp

# Stack representation so far, with the following format
# (Value) -> Address.
# 23
# 22
# 21
# 20
# 19
# 18
# 17
# 16 (argument) -> 16(%rbp)
# 15
# 14
# 13
# 12
# 11
# 10
# 09
# 08 (return address) -> 8(%rbp)
# 07
# 06
# 05
# 04
# 03
# 02
# 01
# 00 (old %rbp) -> current %rbp and %rsp
movl 16(%rbp), %eax

cmpl $0, %eax
jne factorial_non_zero
movl $1, %eax
jmp factorial_end

factorial_non_zero:
cmpl $1, %eax
je factorial_end
decl %eax
pushq %rax
call factorial
movl 16(%rbp), %edi
imull %edi, %eax # Be careful of overflow as we only use 32-bit value instead of 64-bit value.

factorial_end:
movq %rbp, %rsp
popq %rbp
ret
