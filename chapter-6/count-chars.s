# Count the characters until a null (0) byte is reached.

.include "common/linux-x86-32.s"

.equ ST_ARGS, REG_SIZE + REG_SIZE # The argument for function (above return address).

# %ecx: Character count.
# %al (8-bit of %eax): Current character.
# %edx: Current character address.
.type count_chars, @function
.globl count_chars
count_chars:
pushl %ebp
movl %esp, %ebp

# Starting point.
movl $0, %ecx
movl ST_ARGS(%ebp), %edx

count_loop_begin:
movb (%edx), %al # Get current character.

cmpb $0, %al
je count_loop_end

incl %ecx
incl %edx

jmp count_loop_begin

count_loop_end:
movl %ecx, %eax # Move the count into %eax.

movl %ebp, %esp # This is optional as we did not change the stack pointer.
popl %ebp
ret
