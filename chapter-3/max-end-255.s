# %edi: Hold the index of the data item being examined.
# %ebx: Largest data item found.
# %eax: Current data item.

.section .data
data_items:
.long 3,67,34,222,45,75,54,34,44,33,22,11,66,255 # End the data by 255 number, max number before 255.

.section .text
.globl _start
_start:
movl $0, %edi
movl data_items(,%edi,4), %ebx
cmpl $255, %ebx
je exit_loop

start_loop:
incl %edi
movl data_items(,%edi,4), %eax
cmpl %ebx, %eax
jbe start_loop # Jump back if eax less than or equal to ebx (unsigned).
cmpl $255, %eax
je exit_loop
movl %eax, %ebx
jmp start_loop

exit_loop:
movl $1, %eax
int $0x80
