.section .data
.equ SYS_CLOSE, 3
.equ SYS_OPEN, 2
.equ SYS_WRITE, 1
.equ SYS_READ, 0
.equ SYS_EXIT, 60

.equ O_RDONLY, 0
.equ O_CREAT_WRONLY_TRUNC, 01101 # Using octal number.

.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

.equ EOF, 0 # When we hit end of file with read() syscall.

.equ REG_SIZE, 8 # 8 bytes (1 byte = 8 bits, 8 bytes = 64 bits).

.section .bss
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE
.lcomm FD_IN, REG_SIZE
.lcomm FD_OUT, REG_SIZE

.section .text
.equ ST_ARGC, 3 # Expected arguments for executable.
.equ ST_ARGV_0, REG_SIZE # Name of program.
.equ ST_ARGV_1, REG_SIZE + REG_SIZE # Input file name.
.equ ST_ARGV_2, REG_SIZE + REG_SIZE + REG_SIZE # Output file name.

.globl _start
_start:
movq %rsp, %rbp

cmpq $ST_ARGC, (%rbp)
jne exit_argc_err

open_fd_in:
movl $0444, %edx # 3rd argument.
movq $O_RDONLY, %rsi
movq ST_ARGV_1(%rbp), %rdi
movl $SYS_OPEN, %eax
syscall

store_fd_in:
cmpq $0, %rax
jl exit_fd_in_err # Exit if input file not exist (signed).
movq %rax, FD_IN # Access memory address.

open_fd_out:
movl $0644, %edx # 3rd argument.
movq $O_CREAT_WRONLY_TRUNC, %rsi
movq ST_ARGV_2(%rbp), %rdi # Use the first character address of file name.
movl $SYS_OPEN, %eax
syscall

store_fd_out:
movq %rax, FD_OUT

read_loop_begin:
movq $BUFFER_SIZE, %rdx # 3rd argument.
movq $BUFFER_DATA, %rsi # Base address for buffer.
movq FD_IN, %rdi
movl $SYS_READ, %eax
syscall

cmpq $EOF, %rax # Number of bytes returned might exceed 32-bit, hence use 64-bit value.
jle read_loop_end # End loop if we reach end of file (EOF) or got an error (negative value).

pushq %rax # No guarantee that %rax and %rsi will not be changed in callee function, so save bytes read on stack.

movq %rax, %rsi # Bytes read.
movq $BUFFER_DATA, %rdi
call convert_to_uppercase

popq %rdx # Get bytes read.
movq $BUFFER_DATA, %rsi
movq FD_OUT, %rdi
movl $SYS_WRITE, %eax
syscall

cmpq $0, %rax
jl read_loop_end # Exit if write() failed (signed).

jmp read_loop_begin

read_loop_end:
movq %rax, %rbx # Save return code from previous operation.

movq FD_OUT, %rdi
movl $SYS_CLOSE, %eax
syscall

movq FD_IN, %rdi
movl $SYS_CLOSE, %eax
syscall

cmpq $0, %rbx
jl exit_loop_err

exit_normal:
movl $0, %edi
movl $SYS_EXIT, %eax
syscall

exit_argc_err:
movl $42, %r12d
jmp exit_err

exit_fd_in_err:
movl $1, %r12d
jmp exit_err

exit_loop_err:
movl $69, %r12d
jmp exit_err

exit_err:
movq %r12, %rdi
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
