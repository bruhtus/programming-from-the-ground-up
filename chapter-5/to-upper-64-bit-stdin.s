# References:
# - https://stackoverflow.com/a/50013689

.section .data
.equ SYS_CLOSE, 3
.equ SYS_OPEN, 2
.equ SYS_WRITE, 1
.equ SYS_READ, 0
.equ SYS_EXIT, 60

.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

.equ EOF, 0 # When we hit end of file with read() syscall.

.section .bss
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text
.globl _start
_start:

read_loop_begin:
movl $BUFFER_SIZE, %edx
movq $BUFFER_DATA, %rsi
movl $STDIN, %edi
movl $SYS_READ, %eax
syscall

# Still not sure how to handle signal like SIGINT.
cmpl $EOF, %eax
jle exit_err

pushq %rax # Save total bytes read.

movl %eax, %esi
movq $BUFFER_DATA, %rdi
call convert_to_uppercase

movl %eax, %edx
movq $BUFFER_DATA, %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

popq %rbx
decl %ebx # Get the last index from total bytes returned by read().
movb BUFFER_DATA(,%rbx,1), %bl # Use 8-bit value from %rbx.

cmpb $10, %bl # Exit if the last character is line feed (after pressing enter key).
jne read_loop_begin

exit_normal:
movl $0, %edi
movl $SYS_EXIT, %eax
syscall

exit_err:
movl $69, %edi
movl $SYS_EXIT, %eax
syscall

# Check ASCII table, lowercase character translate to bigger number than uppercase character.
.equ LOWERCASE_A, 'a' # Lower boundary of conversion.
.equ LOWERCASE_Z, 'z' # Upper boundary of conversion.
.equ UPPERCASE_CONVERT, 'A' - 'a' # How much we should add to the lowercase character to make it uppercase (65 - 97 = -32).

# %rdi: Base address of buffer.
# %rsi: Buffer length.
convert_to_uppercase:
pushq %rbp
movq %rsp, %rbp

cmpq $0, %rsi
je convert_loop_end # Exit function if buffer length is 0.

movq $0, %r10 # Current character being read.

convert_loop_begin:
movb (%rdi,%r10,1), %r11b # Get the current character byte.

# Go to the next byte unless it is between or equal to 'a' and 'z'.
cmpb $LOWERCASE_A, %r11b
jb next_byte # Maybe we can use unsigned comparison because there is no negative value here (?).
cmpb $LOWERCASE_Z, %r11b
ja next_byte # Maybe we can use unsigned comparison because there is no negative value here (?).

addb $UPPERCASE_CONVERT, %r11b # Convert the character byte to uppercase.
movb %r11b, (%rdi,%r10,1)

next_byte:
incq %r10
cmpq %r10, %rsi # Check if we are at the end of buffer.
ja convert_loop_begin # Loop back if length above index (unsigned).

convert_loop_end:
movq %rbp, %rsp
popq %rbp
ret
