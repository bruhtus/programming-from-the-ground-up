# Return the maximum number from _all_ the list provided as exit code.

.section .text
.globl _start
_start:
movl $0, %ebx # Initialize max number.

# We decrement stack pointer (%esp) everytime we do push.
pushl $42 # End of list.
leal (%esp), %edx # Put the last number in list address.
pushl $11
call max_num

pushl $33 # End of list.
leal (%esp), %edx # Put the last number in list address.
pushl $69
pushl $44
call max_num

pushl $22 # End of list.
leal (%esp), %edx # Put the last number in list address.
pushl $55
pushl $55
pushl $66
call max_num

movl %ebp, %esp # Deallocate local lists.

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
