# Convert ASCII character number to integer.
# Currently only able to convert positive number.
#
# Reference:
# https://stackoverflow.com/a/28202303

.include "common/linux-common.s"
.include "common/linux-x86-64.s"

.section .rodata
input:
.asciz "6a-9!"

.section .text
.globl _start
_start:
movq %rsp, %rbp

movq $input, %rdi
call string_to_integer

movl %eax, %edi # The result is on exit code.
movl $SYS_EXIT, %eax
syscall

# %rdi: Start of string address.
string_to_integer:
pushq %rbp
movq %rsp, %rbp

xorl %eax, %eax # Initialize accumulator to 0.

convert_to_integer_begin:
# Zero-extending byte load.
# Reference:
# https://stackoverflow.com/a/31115069
movzbl (%rdi), %r10d

cmpl $0, %r10d # Null terminator.
je convert_to_integer_end

incq %rdi

# Ignore ASCII character below 48 ('0') and above 57 ('9')
subl $'0', %r10d
jl convert_to_integer_begin
cmpl $9, %r10d
jg convert_to_integer_begin

# Reference:
# https://stackoverflow.com/a/40934959
imull $10, %eax
addl %r10d, %eax # Add current number to accumulator.

jmp convert_to_integer_begin

convert_to_integer_end:
movq %rbp, %rsp
popq %rbp
ret
