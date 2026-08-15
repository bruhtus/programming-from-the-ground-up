# Return the maximum number from _all_ the list provided as exit code.
# AT&T syntax, not intel syntax.

.section .text
.globl _start
_start:
# l in movl stands for long (32-bit value).
# q in movq stands for quad (64-bit value).
movq $0, %rdi

# Stack representation, (value) -> address:
# 15
# 14
# 13
# 12
# 11
# 10
# 09
# 08 (unknown) -> current %rsp (before leaq)
# 07
# 06
# 05
# 04
# 03
# 02
# 01
# 00 (unknown) -> -8(%rsp) and %rbx
leaq -8(%rsp), %rbx # Put the "last number in list" address.

# Stack representation, (value) -> address:
# 15
# 14
# 13
# 12
# 11
# 10
# 09
# 08 (unknown) -> previous %rsp (before leaq)
# 07
# 06
# 05
# 04
# 03
# 02
# 01
# 00 (42) -> current %rsp (after pushq)
pushq $42 # End of list.
pushq $11
call max_num
leaq 8(%rbx), %rsp # Deallocate local list.

pushq $33 # End of list.
pushq $69
pushq $44
call max_num
leaq 8(%rbx), %rsp # Deallocate local list.

pushq $22 # End of list.
pushq $55
pushq $55
pushq $66
call max_num
leaq 8(%rbx), %rsp # Deallocate local list.

movl $60, %eax
syscall

max_num:
pushq %rbp
movq %rsp, %rbp

pushq %rbx # Put the last item address in stack.

movq $0, %rbx # Initialize index.

# Stack representation, (value) -> address:
# 31
# 30
# 29
# 28
# 27
# 26
# 25
# 24 (first argument) -> 16(%rbp)
# 23
# 22
# 21
# 20
# 19
# 18
# 17
# 16 (return address, from call instruction) -> 8(%rbp)
# 15
# 14
# 13
# 12
# 11
# 10
# 09
# 08 (old %rbp) -> current %rbp and previous %rsp
# 07
# 06
# 05
# 04
# 03
# 02
# 01
# 00 (last item address) -> -8(%rbp) and current %rsp
start_search:
leaq 16(%rbp,%rbx,8), %rax # %rax (address value) = %rbp + 16 + (%rbx * 8)
cmpq -8(%rbp), %rax
ja exit_search # Exit if address in %rax > -8(%rbp) (unsigned).
incq %rbx # Increment index by 1.
movq (%rax), %rax # Fetch data and put it back in %rax, reduce register usage.
cmpq %rdi, %rax # %rax - %rdi but did not store result in %rax.
jle start_search # Jump back if %rax <= %rbx (signed).
movq %rax, %rdi
jmp start_search

exit_search:
popq %rbx # Restore previous last item address.
movq %rbp, %rsp
popq %rbp
ret
