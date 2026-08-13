.section .text
.globl _start
_start:
pushl $4 # For function argument.
call factorial
addl $4, %esp # Deallocate previous argument by moving the stack pointer.

movl %eax, %ebx # Put the result in ebx as status code for exit() system call.

movl $1, %eax
int $0x80

.type factorial, @function # This is optional unless using factorial in another program.
factorial:
pushl %ebp
movl %esp, %ebp

# Stack representation so far, with the following format
# (Value) -> Address.
# 11
# 10
# 09
# 08 (argument) -> 8(%ebp)
# 07
# 06
# 05
# 04 (return address) -> 4(%ebp)
# 03
# 02
# 01
# 00 (old %ebp) -> current %ebp and %esp
movl 8(%ebp), %eax

# For factorial 0.
cmpl $0, %eax
jne factorial_non_zero
movl $1, %eax
jmp factorial_end

factorial_non_zero:
cmpl $1, %eax
je factorial_end # Prevent adding one more stack frame for factorial 0.
decl %eax
pushl %eax # For function argument.
call factorial
movl 8(%ebp), %ebx
imull %ebx, %eax

factorial_end:
movl %ebp, %esp
popl %ebp
ret
