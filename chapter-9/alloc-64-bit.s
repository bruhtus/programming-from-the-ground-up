# Reference:
# https://stackoverflow.com/a/43006616
.section .data
heap_begin:
.quad 0
current_break: # Point to one location past the memory we are managing.
.quad 0

.equ UNAVAILABLE, 0
.equ AVAILABLE, 1
.equ SYS_BRK, 12 # x86-64 brk() syscall number.

.equ HEADER_SIZE, 8 # Available marker + memory size. 4 bytes each maybe because int type?
.equ HDR_AVAILABLE_OFFSET, 0 # Start of available marker.
.equ HDR_SIZE_OFFSET, 4 # Start of memory size info.

.section .text

# %rdi: Requested memory size.
# %rax: Memory block address.
.globl alloc
.type alloc, @function
alloc:
pushq %rbp
movq %rsp, %rbp

pushq %rdi

cmpq $0, heap_begin # We use cmpq instead of cmpl just to be safe with 64-bit address format.
jne skip_init # Already initialized.

# Looks like if we provide 0 as the address for linux syscall brk() parameter,
# we will get the current break address (?).
#
# Reference:
# https://stackoverflow.com/questions/79724758/what-difference-between-brk-and-syscallsys-brk#79726797
movl $0, %edi
movl $SYS_BRK, %eax
syscall

popq %rdi

# Looks like the linux syscall brk() has different return value from
# glibc brk() wrapper. The behavior in `man brk` is for the glibc wrapper
# return value. For the linux syscall brk() return value is that brk() return
# the new break point on success and return the current break point on failure.
#
# Increment the last valid address or current break address because we want the
# next address after those last valid address as the start of heap list.
incq %rax

# Because the heap consist of memory between heap_begin and current_break,
# setup current_break the same as heap_begin means that we have 0 byte in
# the heap list. So when we allocate the memory for the first time, we will
# request new memory block.
movq %rax, current_break
movq %rax, heap_begin

skip_init:
movq heap_begin, %rax
movq current_break, %r10

alloc_loop_begin:
cmpq %r10, %rax
je move_break_point

cmpl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%rax)
je next_location

movl HDR_SIZE_OFFSET(%rax), %r11d
cmpl %r11d, %edi
jle alloc_here

next_location:
addq $HEADER_SIZE, %rax # Move the address at the beginning of actual memory location (after header?).
addq %r11, %rax # Move the address at beginning of next memory location header (?).

jmp alloc_loop_begin

alloc_here:
movl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%rax)
addq $HEADER_SIZE, %rax

jmp alloc_exit

move_break_point:
# The break point moved to one location after the actual memory.
addq $HEADER_SIZE, %r10
addq %rdi, %r10

# Save the data that will be replaced.
pushq %rax
pushq %rdi

movq %r10, %rdi
movl $SYS_BRK, %eax
syscall

# According to the book, brk() syscall should return 0 if it failed to change
# the break point. But according to the `man brk`, linux syscall brk() will
# return the current break point if it failed (?). Still not sure when brk()
# failed.
cmpl $0, %eax
je brk_err

popq %rdi
popq %rax

movl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%rax)
movl %edi, HDR_SIZE_OFFSET(%rax)

addq $HEADER_SIZE, %rax # Move to the start of actual memory.
movq %r10, current_break

jmp alloc_exit

brk_err:
# Reference:
# https://stackoverflow.com/a/33668295
xor %eax, %eax # On failure, return 0.

alloc_exit:
movq %rbp, %rsp
popq %rbp
ret

# %rdi: Address of memory block.
.globl dealloc
.type dealloc, @function
dealloc:
pushq %rbp
movq %rsp, %rbp

subq $HEADER_SIZE, %rdi # Move to the start of header info.
movl $AVAILABLE, HDR_AVAILABLE_OFFSET(%rdi)

movq %rbp, %rsp
popq %rbp
ret
