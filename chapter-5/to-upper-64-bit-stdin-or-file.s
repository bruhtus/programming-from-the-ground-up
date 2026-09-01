# If no arguments provided, use stdin and stdout.
# If the argument for input and output file provided, use those files.

.equ SYS_CLOSE, 3
.equ SYS_OPEN, 2
.equ SYS_WRITE, 1
.equ SYS_READ, 0
.equ SYS_EXIT, 60

.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

.equ O_RDONLY, 0
.equ O_CREAT_WRONLY_TRUNC, 01101 # Using octal number.

.equ REG_SIZE, 8 # 8 bytes (1 byte = 8 bits, 8 bytes = 64 bits).
.equ EOF, 0 # When we hit end of file with read() syscall.
.equ BUFFER_SIZE, 500 # As long as the buffer size not exceeding 32-bit value, we can use long instruction (?).

.section .rodata
argc_err_msg:
.string "Need input and output files (no more, no less)\n"
# The current address in section .rodata - the first address from message label.
# Reference: https://stackoverflow.com/a/63928977
.equ argc_err_msg_len, (. - argc_err_msg)
input_fd_err_msg:
.string "Failed to read input file\n"
.equ input_fd_err_msg_len, (. - input_fd_err_msg)
loop_err_msg:
.string "Failure in loop mechanism\n"
.equ loop_err_msg_len, (. - loop_err_msg)

.equ ST_ARGV_0, REG_SIZE # Program name.
.equ ST_ARGV_1, REG_SIZE + REG_SIZE # Input file name.
.equ ST_ARGV_2, REG_SIZE + REG_SIZE + REG_SIZE # Output file name.

.section .text
.globl _start
_start:
movq %rsp, %rbp

subq $BUFFER_SIZE, %rsp

# Argument count (argc) has minimum value of 1, because of program name (?).
cmpl $1, (%rbp)
je use_stdin_stdout

# Check if the argument count (argc) is 3
# (program name, input file name, output file name) for non-stdin.
cmpl $3, (%rbp)
jne exit_argc_err

input_fd:
movl $0444, %edx # 3rd argument.
movl $O_RDONLY, %esi
movq ST_ARGV_1(%rbp), %rdi
movl $SYS_OPEN, %eax
syscall

cmpl $0, %eax
jl exit_input_fd_err

movl %eax, %r12d

output_fd:
movl $0644, %edx # 3rd argument.
movl $O_CREAT_WRONLY_TRUNC, %esi
movq ST_ARGV_2(%rbp), %rdi
movl $SYS_OPEN, %eax
syscall

movl %eax, %r13d

jmp read_loop_begin

# Use callee saved register to indicate using stdin and stdout or files.
use_stdin_stdout:
movl $STDIN, %r12d
movl $STDOUT, %r13d

read_loop_begin:
movl $BUFFER_SIZE, %edx
leaq -BUFFER_SIZE(%rbp), %rsi # Put the start of buffer address.
movl %r12d, %edi
movl $SYS_READ, %eax
syscall

cmpl $EOF, %eax
jle read_loop_end

pushq %rax # Save total bytes read.

movl %eax, %esi
leaq -BUFFER_SIZE(%rbp), %rdi
call convert_to_uppercase

# Store total bytes read back.
# No guarantee %rax content will not be changed after function call.
popq %rbx

movl %ebx, %edx
leaq -BUFFER_SIZE(%rbp), %rsi
movl %r13d, %edi
movl $SYS_WRITE, %eax
syscall

cmpl $STDIN, %r12d
jne read_non_stdin

decl %ebx # Get the last index from total bytes returned by read().
movb -BUFFER_SIZE(%rbp,%rbx,1), %bl # Use 8-bit value from %rbx.

cmpb $10, %bl # Exit if the last character is line feed (after pressing enter key).
jne read_loop_begin
jmp read_loop_end # Prevent entering non-stdin instructions.

read_non_stdin:
cmpq $0, %rax
jl read_loop_end # Exit if write() failed (signed).

jmp read_loop_begin

read_loop_end:
movl %eax, %ebx

cmpl $STDIN, %r12d
je check_loop_err

movl %r13d, %edi
movl $SYS_CLOSE, %eax
syscall

movl %r12d, %edi
movl $SYS_CLOSE, %eax
syscall

check_loop_err:
cmpl $0, %ebx
jl exit_loop_err

exit_normal:
movl $0, %edi
movl $SYS_EXIT, %eax
syscall

exit_argc_err:
movl $argc_err_msg_len, %edx
movq $argc_err_msg, %rsi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall
movl $42, %r12d
jmp exit_err

exit_input_fd_err:
movl $input_fd_err_msg_len, %edx
movq $input_fd_err_msg, %rsi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall
movl $1, %r12d
jmp exit_err

exit_loop_err:
movl $loop_err_msg_len, %edx
movq $loop_err_msg, %rsi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall
movl $69, %r12d
jmp exit_err

exit_err:
movl %r12d, %edi
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

cmpl $0, %esi
je convert_loop_end

movl $0, %r10d # Current index.

convert_loop_begin:
movb (%rdi,%r10,1), %r11b # Get the current character byte.

# Go to the next byte unless it is between or equal to 'a' and 'z'.
cmpb $LOWERCASE_A, %r11b
jb next_byte # Unsigned comparison because there's no negative value (jump below).
cmpb $LOWERCASE_Z, %r11b
ja next_byte # Unsigned comparison because there's no negative value (jump above).

addb $UPPERCASE_CONVERT, %r11b # Convert the character byte to uppercase.
movb %r11b, (%rdi,%r10,1)

next_byte:
incl %r10d
cmpl %r10d, %esi # Check if we are at the end of buffer.
ja convert_loop_begin # Loop back if length above index (unsigned).

convert_loop_end:
movq %rbp, %rsp
popq %rbp
ret
