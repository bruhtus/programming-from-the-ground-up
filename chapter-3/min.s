# %edi: Hold the index of the data item being examined.
# %ebx: Smallest data item found.
# %eax: Current data item.

.section .data
data_items:
.long 67,3,34,222,45,75,54,2,44,33,22,11,66,0 # End the data by 0 number.

.section .text
.globl _start
_start:
movl $0, %edi
movl data_items(,%edi,4), %ebx # Treat first data as smallest data.
cmpl $0, %ebx
je exit_loop

start_loop:
incl %edi
movl data_items(,%edi,4), %eax
cmpl %ebx, %eax
jae start_loop # Jump back if eax greater than or equal to ebx (unsigned).
cmpl $0, %eax
je exit_loop
movl %eax, %ebx
jmp start_loop

exit_loop:
movl $1, %eax
int $0x80
