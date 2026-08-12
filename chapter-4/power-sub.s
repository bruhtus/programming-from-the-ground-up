.section .text
.globl _start
_start:
pushl $3 # Second argument.
pushl $2 # First argument.
call power
addl $8, %esp

pushl %eax

pushl $2 # Second argument.
pushl $5 # First argument.
call power
addl $8, %esp

popl %ebx

# Reference:
# https://www.felixcloutier.com/x86/sub (use destination and source operand term)
subl %eax, %ebx # final (in ebx) = first answer (in ebx) - second answer (in eax)

movl $1, %eax
int $0x80

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
