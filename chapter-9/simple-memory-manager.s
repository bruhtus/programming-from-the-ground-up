# Allocate and deallocate memory as requested.
#
# The memory reserved look like this:
# | Available marker | Memory size | Actual memory location |
#                                   ^Returned pointer points here.
#
# We add some kind of header header information, such as
# available/unavailable marker and memory size, before the requested
# memory location.
#
# Reference: https://stackoverflow.com/a/44876873


.section .data
heap_begin: # Start of memory we are managing.
.long 0

current_break: # Point to one location past the memory we are managing.
.long 0

.equ HEADER_SIZE, 8 # Memory region header (available marker, memory size).
.equ HDR_AVAILABLE_OFFSET, 0 # Header available marker location.
.equ HDR_SIZE_OFFSET, 4 # Header memory size location.

.equ UNAVAILABLE, 0 # Unavailable memory mark.
.equ AVAILABLE, 1 # Available memory mark.
.equ SYS_BRK, 45 # x86 32-bit brk() syscall code.
.equ LINUX_SYSCALL, 0x80

.section .text
.globl allocate_init
.type allocate_init, @function
allocate_init:
pushl %ebp
movl %esp, %ebp

movl $0, %ebx # Return the last valid usable address.
movl $SYS_BRK, %eax
int $LINUX_SYSCALL

# Looks like the linux syscall brk() has different return value from
# glibc brk() wrapper. The behavior in `man brk` is for the glibc wrapper
# return value. For the linux syscall brk() return value is that brk() return
# the new break point on success and return the current break point on failure.
#
# Increment the last valid address because we want the next address after
# those last valid address as the start of heap list.
incl %eax

# Because the heap consist of memory between heap_begin and current_break,
# setup current_break the same as heap_begin means that we have 0 byte in
# the heap list. So when we allocate the memory for the first time, we will
# request new memory block.
movl %eax, current_break
movl %eax, heap_begin

movl %ebp, %esp
popl %ebp
ret

.equ ST_MEM_SIZE, 8 # Input requested memory size position in the stack.

# This function check if there are any free blocks in the heap list of memory.
# If there is a free blocks with the requested size in the heap, we will take
# those blocks, and if not, we asks linux for a new block of memory to be added
# to the heap list and move the current_break to the new memory block.
#
# Input: Requested memory size.
# Output: Pointer to requested memory location or 0 if no memory available.
#
# %ecx: Hold requested memory size.
# %eax: Current memory block being examined.
# %ebx: Current break position.
# %edx: Size of current memory block being examined.
.globl allocate
.type allocate, @function
allocate:
pushl %ebp
movl %esp, %ebp

movl ST_MEM_SIZE(%ebp), %ecx
movl heap_begin, %eax
movl current_break, %ebx

alloc_loop_begin:
cmpl %ebx, %eax
je move_break_point

cmpl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%eax)
je next_location

movl HDR_SIZE_OFFSET(%eax), %edx
cmpl %edx, %ecx
jle allocate_here

next_location:
addl $HEADER_SIZE, %eax # Move the address at the beginning of actual memory location (after header?).
addl %edx, %eax # Move the address at beginning of next memory location header (?).

jmp alloc_loop_begin

allocate_here:
movl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%eax) # Set the memory block as unavailable.
addl $HEADER_SIZE, %eax # Move the address at the beginning of actual memory location (after header?).

jmp allocate_exit

move_break_point:
# The break point moved to one location after the actual memory.
addl $HEADER_SIZE, %ebx
addl %ecx, %ebx

pushl %eax
pushl %ecx
pushl %ebx
movl $SYS_BRK, %eax
int $LINUX_SYSCALL

# According to the book, brk() syscall should return 0 if it failed to change
# the break point. But according to the `man brk`, linux syscall brk() will
# return the current break point if it failed (?). Still not sure when brk()
# failed.
cmpl $0, %eax
je brk_err

popl %ebx
popl %ecx
popl %eax

movl $UNAVAILABLE, HDR_AVAILABLE_OFFSET(%eax) # We will give this memory block to the program.
movl %ecx, HDR_SIZE_OFFSET(%eax)

addl $HEADER_SIZE, %eax # Move to the start of actual memory.

movl %ebx, current_break # Set the new break point.

jmp allocate_exit

brk_err:
movl $0, %eax # On failure, return 0.

allocate_exit:
movl %ebp, %esp
popl %ebp
ret

.equ ST_MEM_BLOCK, 8

# This function give back the memory block to the heap list of memory after we
# are done using it.
#
# Input: Address of memory block.
# Output: None.
.globl deallocate
.type deallocate, @function
deallocate:
pushl %ebp
movl %esp, %ebp

movl ST_MEM_BLOCK(%ebp), %eax

subl $HEADER_SIZE, %eax # Move to the start of header info.
movl $AVAILABLE, HDR_AVAILABLE_OFFSET(%eax)

movl %ebp, %esp
popl %ebp
ret
