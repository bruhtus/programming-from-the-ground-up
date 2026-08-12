# Because we did not use the full 64-bit register, we can use the subset 32-bit
# register for some of the operations.
#
# References:
# - https://stackoverflow.com/a/5486040
# - https://stackoverflow.com/q/38303333 (Advantage using 32-bit register in 64-bit system)

.section .text
.globl _start
_start:
pushq $3 # Push second argument.
pushq $2 # Push first argument.
call power
addq $16, %rsp # Deallocate previous arguments (8 bytes + 8 bytes) by moving the stack pointer up.

pushq %rax # Save return value from the first function call (replacing the previous first argument value in stack).

pushq $2 # Push second argument.
pushq $5 # Push first argument.
call power
addq $16, %rsp

popq %rdi # Save the first function call return value in rdi.

addl %eax, %edi # final (in rdi) = first answer (in rdi) + second answer (in rax)

movl $60, %eax # Try using 32-bit value instead of 64-bit value.
syscall

# %rax: Hold temporary result/answer for power operation.
# %rdi: Hold base number.
# %rbx: Hold power number.
#
# First argument is the base number.
# Second argument is the power number.
#
# The power must be 1 or greater.
.type power, @function
power:
pushq %rbp # Save previous base pointer.
movq %rsp, %rbp # Make the current stack pointer as the base pointer for this stack frame.

# Using subl instead of subq for rsp can cause the memory address for stack
# pointer to be truncated to 32-bit address (like 0xffffddac) rather than
# 64-bit address (like 0x7fffffffddac), which can cause problem when doing
# push or pop that need 64-bit address.
subq $4, %rsp # Allocate space for local variable.

# Stack representation so far (36 bytes in stack):
# 35
# 34
# 33
# 32
# 31
# 30
# 29
# 28 (second argument) -> 24(%rbp)
# 27
# 26
# 25
# 24
# 23
# 22
# 21
# 20 (first argument) -> 16(%rbp)
# 19
# 18
# 17
# 16
# 15
# 14
# 13
# 12 (return address)
# 11
# 10
# 09
# 08
# 07
# 06
# 05
# 04 (%rbp)
# 03
# 02
# 01
# 00 (local variable) -> -4(%rbp) and %rsp
movl 16(%rbp), %edi # Put first argument in rdi.
movl 24(%rbp), %ebx # Put second argument in rbx.
movl %edi, -4(%rbp) # Store current result.

power_start_loop:
cmpl $1, %ebx
je power_exit_loop
movl -4(%rbp), %eax
imull %edi, %eax # Multiply current result by the base number (signed).
movl %eax, -4(%rbp) # Store new result.
decl %ebx # Decrement power number.
jmp power_start_loop

power_exit_loop:
movl -4(%rbp), %eax # Put the final result in %rax as return value from the function.
movq %rbp, %rsp # Deallocate stack frame by moving back stack pointer to base pointer.
popq %rbp # Restore previous base pointer.
ret
