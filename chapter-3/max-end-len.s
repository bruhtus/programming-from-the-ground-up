# %edi: Hold the index of the data item being examined.
# %ebx: Largest data item found.
# %eax: Current data item.
# %ecx: Total index (start from 0).

.section .data
data_items:
.long 3,67,34,222,45,75,54,34,44,33,22,11,66,255
# References:
# - https://stackoverflow.com/a/52866028
# - http://alanclements.org/assembletime.html
data_len = (. - data_items) / 4 # Each data is 4 bytes (assemble time constant or processing during assembling).

.section .text
.globl _start
_start:
movl $0, %edi
movl data_items(,%edi,4), %ebx
movl $data_len - 1, %ecx # Save total index, index start from 0.

start_loop:
cmpl %edi, %ecx
je exit_loop
incl %edi
movl data_items(,%edi,4), %eax
cmpl %ebx, %eax
jbe start_loop # Jump back if eax less than or equal to ebx (unsigned).
movl %eax, %ebx
jmp start_loop

exit_loop:
movl $1, %eax
int $0x80
