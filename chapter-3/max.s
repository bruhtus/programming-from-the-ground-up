# %edi: Hold the index of the data item being examined.
# %ebx: Largest data item found.
# %eax: Current data item.

.section .data
data_items:
# Why do we need to use .long and not .byte or .int?
.long 3,67,34,222,45,75,54,34,44,33,22,11,66,0 # End the data by 0 number.

.section .text
.globl _start
_start:
movl $0, %edi
movl data_items(,%edi,4), %eax # Load the first data.
movl %eax, %ebx

start_loop:
cmpl $0, %eax
je exit_loop # Jump to exit_loop label if value in eax is 0.
incl %edi # Increment the index by one.
movl data_items(,%edi,4), %eax # Load the next data.
cmpl %ebx, %eax
jle start_loop # Jump back to start_loop label if current value less than or equal largest value.
movl %eax, %ebx # Save the value if it's larger than the current largest value.
jmp start_loop # Jump back to start_loop label.

exit_loop:
# %ebx is the status code for the exit system call and it already has the largest number from data items.
movl $1, %eax # Number 1 is the exit() system call on linux.
int $0x80 # Interrupt with terminate signal.
