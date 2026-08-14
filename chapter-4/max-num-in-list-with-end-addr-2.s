# Return the maximum number from _all_ the list provided as exit code.

.section .text
.globl _start
_start:
movl $0, %ebx # Initialize max number.

leal -4(%esp), %edx # Put the last number in list address.

# Every push decrement stack pointer (%esp) by 4 bytes.
pushl $42 # End of list.
pushl $11
call max_num
leal 4(%edx), %esp # Deallocate local list.

pushl $33 # End of list.
pushl $69
pushl $44
call max_num
leal 4(%edx), %esp # Deallocate local list.

pushl $22 # End of list.
pushl $55
pushl $55
pushl $66
call max_num
leal 4(%edx), %esp # Deallocate local list.

movl $1, %eax
int $0x80

max_num:
pushl %ebp
movl %esp, %ebp

movl $0, %ecx # Initialize index.

start_search:
leal 8(%ebp,%ecx,4), %eax
cmpl %edx, %eax
ja exit_search # Exit if address in eax > edx (unsigned).
incl %ecx
movl (%eax), %eax # Fetch data and put it back in eax, reduce register usage.
cmpl %ebx, %eax # Similar to eax - ebx but did not store the result in eax.
jle start_search # Jump back if eax <= ebx (signed).
movl %eax, %ebx
jmp start_search

exit_search:
movl %ebp, %esp
popl %ebp
ret
