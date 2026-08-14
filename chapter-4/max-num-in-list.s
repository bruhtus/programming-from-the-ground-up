# Return the maximum number from _all_ the list provided as exit code.

.section .text
.globl _start
_start:
movl $0, %ebx # Initialize max number.

pushl $0 # End of list.
pushl $42
pushl $11
call max_num

pushl $0 # End of list.
pushl $69
pushl $33
pushl $44
call max_num

pushl $0 # End of list.
pushl $22
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
movl 8(%ebp,%ecx,4), %eax # Iterate 4 bytes of data.
cmpl $0, %eax
je exit_search
incl %ecx # Increment index by 1.
cmpl %ebx, %eax # Similar to eax - ebx but did not store the result in eax.
jle start_search # Jump back if eax <= ebx (signed).
movl %eax, %ebx
jmp start_search

exit_search:
movl %ebp, %esp
popl %ebp
ret
