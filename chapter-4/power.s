.section .text
.globl _start
_start:
pushl $3 # Push second argument.
pushl $2 # Push first argument.
call power # Call the function.
addl $8, %esp # Deallocate previous arguments (4 bytes + 4 bytes) by moving the stack pointer up.

pushl %eax # Save return value from the first function call (replacing the previous first argument value in stack).

pushl $2 # Push second argument.
pushl $5 # Push first argument.
call power
addl $8, %esp

popl %ebx # Save the first function call return value in ebx.

addl %eax, %ebx # final (in ebx) = second answer (in eax) + first answer (in ebx)

movl $1, %eax # Specify exit() system call in linux.
int $0x80 # Interrupt with "terminate" instruction.

# %eax: Hold temporary result/answer for power operation.
# %ebx: Hold base number.
# %ecx: Hold power number.
#
# First argument is the base number.
# Second argument is the power number.
#
# The power must be 1 or greater.
.type power, @function
power:
pushl %ebp # Save previous base pointer.
movl %esp, %ebp # Make the current stack pointer as the base pointer for this stack frame.
subl $4, %esp # Allocate space for local variable.

# Stack representation so far (20 bytes in stack):
# 19
# 18
# 17
# 16 (second argument) -> 12(%ebp)
# 15
# 14
# 13
# 12 (first argument) -> 8(%ebp)
# 11
# 10
# 09
# 08 (return address)
# 07
# 06
# 05
# 04 (%ebp)
# 03
# 02
# 01
# 00 (local variable) -> -4(%ebp) and %esp
movl 8(%ebp), %ebx # Put first argument in ebx.
movl 12(%ebp), %ecx # Put second argument in ecx.
movl %ebx, -4(%ebp) # Store current result.

power_start_loop:
cmpl $1, %ecx
je power_exit_loop # If the power number is 1, exit.
movl -4(%ebp), %eax
imull %ebx, %eax # Multiply current result by the base number (signed).
movl %eax, -4(%ebp) # Store new result.
decl %ecx # Decrement power number.
jmp power_start_loop

power_exit_loop:
movl -4(%ebp), %eax # Put final result in %eax as return value from the function.
movl %ebp, %esp # Deallocate stack frame by moving stack pointer to base pointer.
popl %ebp # Restore previous base pointer.
ret
