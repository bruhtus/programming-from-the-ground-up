# Looks like there is a difference when using .equ and = (equal sign) to set
# a number to a symbol. When using .equ, we can not edit the symbol value later
# on (immutable). When using = (equal sign), we can edit the symbol value later
# on (mutable).
# Reference: https://stackoverflow.com/a/28952568
.section .data
# System call number in 32-bit x86.
.equ SYS_CLOSE, 6
.equ SYS_OPEN, 5
.equ SYS_WRITE, 4
.equ SYS_READ, 3
.equ SYS_EXIT, 1

# Check /usr/include/asm-generic/fcntl.h for various open() syscall options.
# We can combine the options by using bitwise OR (|).
.equ O_RDONLY, 0
# Combination of O_CREAT, O_WRONLY, O_TRUNC (?), but why using octal number?
# Maybe because octal number can be converted up to 3 bits (111)?
# The book use 03101 but using 01101 is fine? Do we need the extra 02000 (O_APPEND)?
# Maybe 02000 (O_APPEND) is for concurrent process?
# (Reference: https://stackoverflow.com/a/70626032)
.equ O_CREAT_WRONLY_TRUNC, 01101

.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

.equ LINUX_SYSCALL, 0x80
.equ EOF, 0 # The return value of read() syscall when we hit the end of file.

.section .bss
.equ BUFFER_SIZE, 500 # Is this evaluated during assemble time? So the section placement does not matter (?).
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text
# Stack positions.
.equ REG_SIZE, 4 # 4 bytes (1 byte = 8 bits, 4 bytes = 32 bits).
.equ ST_SIZE_RESERVE, REG_SIZE + REG_SIZE
.equ ST_FD_IN, -(REG_SIZE)
.equ ST_FD_OUT, -(REG_SIZE + REG_SIZE)
.equ ST_ARGC, 3 # Expected arguments for executable.
.equ ST_ARGV_0, REG_SIZE # Name of program.
.equ ST_ARGV_1, REG_SIZE + REG_SIZE # Input file name.
.equ ST_ARGV_2, REG_SIZE + REG_SIZE + REG_SIZE # Output file name.

.globl _start
_start:
movl %esp, %ebp

# Looks like the argument count (argc) for the executable is in
# the first argument of _start function (?).
cmpl $ST_ARGC, (%ebp)
jne exit_err

subl $ST_SIZE_RESERVE, %esp # Allocate for file descriptors input and output file.

open_fd_in:
movl $SYS_OPEN, %eax # Call open() syscall.
movl ST_ARGV_1(%ebp), %ebx # Put file name into %ebx.
movl $O_RDONLY, %ecx
movl $0444, %edx # Do we need this? Did not see any difference whether provide this or not in input file.
int $LINUX_SYSCALL

store_fd_in:
cmpl $0, %eax
jl exit_err # Exit if open() syscall return value less than 0, like file not exist (signed).
movl %eax, ST_FD_IN(%ebp) # Return value from open() syscall.

open_fd_out:
movl $SYS_OPEN, %eax
movl ST_ARGV_2(%ebp), %ebx
movl $O_CREAT_WRONLY_TRUNC, %ecx # Create the file if not exist, or replace the content if the file exist.
movl $0644, %edx # File permission for the create (if not exist) output file (?).
int $LINUX_SYSCALL

store_fd_out:
movl %eax, ST_FD_OUT(%ebp) # Return value from open() syscall.

# Process the contents every $BUFFER_SIZE.
read_loop_begin:
movl $SYS_READ, %eax
movl ST_FD_IN(%ebp), %ebx # Get input file descriptor (or endpoint?).
movl $BUFFER_DATA, %ecx # Get address to read into.
movl $BUFFER_SIZE, %edx
int $LINUX_SYSCALL

# How do read() know if it is end of file?
# Is read() reading the data until the end character (regardless filling
# $BUFFER_SIZE or not), and then on the next reading will return end of file marker?
cmpl $EOF, %eax # Check return value from read() syscall.
jle read_loop_end # Exit if we reach end of file (EOF) or got an error which is negative value (signed).

pushl $BUFFER_DATA
pushl %eax # Buffer size from read() syscall return value.
call convert_to_uppercase
popl %eax # Get the buffer size back.
addl $REG_SIZE, %esp # Deallocate $BUFFER_DATA address on stack.

# Write to output file.
movl %eax, %edx
movl $SYS_WRITE, %eax
movl ST_FD_OUT(%ebp), %ebx
movl $BUFFER_DATA, %ecx
int $LINUX_SYSCALL

jmp read_loop_begin

read_loop_end:
movl $SYS_CLOSE, %eax
movl ST_FD_OUT(%ebp), %ebx # Close output file descriptor.
int $LINUX_SYSCALL

movl $SYS_CLOSE, %eax
movl ST_FD_IN(%ebp), %ebx # Close input file descriptor.
int $LINUX_SYSCALL

movl $SYS_EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL

exit_err: # Exit if argument count for executable is incorrect.
movl $SYS_EXIT, %eax
movl $69, %ebx
int $LINUX_SYSCALL

# Check ASCII table, lowercase character translate to bigger number than uppercase character.
.equ LOWERCASE_A, 'a' # Lower boundary of conversion.
.equ LOWERCASE_Z, 'z' # Upper boundary of conversion.
.equ UPPERCASE_CONVERT, 'A' - 'a' # How much we should add to the lowercase character to make it uppercase (65 - 97 = -32).

.equ ST_BUFFER_LEN, REG_SIZE + REG_SIZE # Offset to where buffer length is.
.equ ST_BUFFER, REG_SIZE + REG_SIZE + REG_SIZE # Offset to where actual buffer is.

# First parameter is the location of buffer.
# Second parameter is the length of buffer.
# Output: Overwrite the current buffer with uppercase version.
#
# %eax: Beginning of buffer.
# %ebx: Length of buffer.
# %edi: Current buffer offset.
# %cl: Current byte being examined (first 8 bit of %ecx).
convert_to_uppercase:
pushl %ebp
movl %esp, %ebp

movl ST_BUFFER(%ebp), %eax
movl ST_BUFFER_LEN(%ebp), %ebx
movl $0, %edi # Current character being read.

cmpl $0, %ebx
je convert_loop_end # Exit if the length of buffer is 0.

convert_loop_begin:
movb (%eax,%edi,1), %cl # Get the current character byte (?).

# Go to the next byte unless it is between or equal to 'a' and 'z'.
# Reference for unsigned vs signed comparison:
# https://stackoverflow.com/a/7510447
cmpb $LOWERCASE_A, %cl
jb next_byte # Maybe we can use unsigned comparison because there is no negative value here (?).
cmpb $LOWERCASE_Z, %cl
ja next_byte # Maybe we can use unsigned comparison because there is no negative value here (?).

addb $UPPERCASE_CONVERT, %cl # Convert the byte to uppercase.
movb %cl, (%eax,%edi,1)

next_byte:
incl %edi
cmpl %edi, %ebx
jne convert_loop_begin

convert_loop_end:
movl %ebp, %esp
popl %ebp
ret
