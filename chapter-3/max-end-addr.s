# %edi: Hold the index of the data item being examined.
# %ebx: Largest data item found.
# %eax: Current data item.
# %ecx: The address of last item.
# %edx: The address of current item.

.section .data
data_items:
.long 3,67,34,222,45,75,54,34,44,33,22,11,66,255 # Each data is 4 bytes.
# References:
# - https://stackoverflow.com/a/52866028
# - http://alanclements.org/assembletime.html
last_item_offset = . - data_items - 4 # In bytes, start from 0 (assemble time constant or processing during assembling).

# Check register content on gdb with command:
# - info registers
# - info registers eax
# - i r eax (abbreviation)
.section .text
.globl _start
_start:
movl $0, %edi
movl data_items(,%edi,4), %ebx # Initialize ebx.
movl $data_items, %ecx # Save the base address of data_items.
addl $last_item_offset, %ecx # Add offset to the last item.
leal data_items(,%edi,4), %edx # Save current index address.
cmpl %ecx, %edx
je exit_loop

start_loop:
incl %edi
leal data_items(,%edi,4), %edx # Save current index address.
cmpl %ecx, %edx
ja exit_loop # Jump to exit_loop if edx greater than ecx (unsigned).
movl (%edx), %eax
cmpl %ebx, %eax
jbe start_loop # Jump back if eax less than or equal to ebx (unsigned).
movl %eax, %ebx
jmp start_loop

exit_loop:
movl $1, %eax
int $0x80
