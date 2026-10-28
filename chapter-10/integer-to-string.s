# Currently only able to convert positive number and 4 digit number (BUFFER_SIZE).
# Still not sure how to convert negative number to string so that we can use
# write() to print the number.
#
# Reference:
# https://stackoverflow.com/questions/66269798/convert-integer-to-string-in-assembly-64-bit-nasm-as-fast-as-possible

.include "common/linux-common.s"
.include "common/linux-x86-64.s"

.equ BUFFER_SIZE, 4

.section .rodata
input:
.long 6942
newline_char:
.ascii "\n"

.section .bss
.lcomm conversion_buffer, BUFFER_SIZE

.section .text
.globl _start
_start:
movq %rsp, %rbp

movl $BUFFER_SIZE, %edx
movq $conversion_buffer, %rsi
movl input, %edi
call integer_to_string

movl $BUFFER_SIZE, %edx
movq $conversion_buffer, %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl exit_err

movl $1, %edx
movq $newline_char, %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl exit_err

movl $0, %edi
movl $SYS_EXIT, %eax
syscall

exit_err:
movl $69, %edi
movl $SYS_EXIT, %eax
syscall

# %rdi: Integer value.
# %rsi: Buffer address.
# %rdx: Buffer size.
integer_to_string:
pushq %rbp
movq %rsp, %rbp

movl $0, %r10d # Current character count.
movl $10, %r11d # Divide integer value by 10.
movl %edi, %eax # For div instruction, which is %edx:%eax.
movl %edx, %ecx # Copy buffer size because we will be using %edx for division.

conversion_begin:
# Looks like we need to zero out the %edx, because the operator is %edx:%eax (?).
# We store the quotient (hasil bagi) in %eax and the remainder in %edx (?).
# References:
# - https://stackoverflow.com/a/38416896
# - https://stackoverflow.com/a/43575674
# - https://stackoverflow.com/a/76332918 (unsigned division of 64-bit value)
movl $0, %edx

divl %r11d

# We convert the last number into ASCII character.
# Number 9 will be converted into ASCII character 57.
addl $'0', %edx

# Put the result in the stack from last number to first number so that we can
# combine the number by popping off from the stack.
pushq %rdx

incl %r10d

cmpl $0, %eax
je copy_conversion

jmp conversion_begin

copy_conversion:
popq %rax
movb %al, (%rsi)

decl %r10d
decl %ecx
incq %rsi # Point to next byte.

cmpl $0, %r10d
je conversion_end

# Either all the number has been copied or we exhaust the buffer limit.
# Prevent buffer overflow (?).
cmpl $0, %ecx
je conversion_end

jmp copy_conversion

conversion_end:
movq %rbp, %rsp
popq %rbp
ret
