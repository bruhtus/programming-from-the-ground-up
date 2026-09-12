# Depends on:
# - write-record.s

.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-32.s"

.section .rodata
record_1:
record_1_first_name:
.asciz "Anumu" # 6 characters (A, n, u, m, u, \0), similar to .string (unless specified).
# Looks like we can use .skip directive instead of .rept macro (?).
# References:
# - https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_node/as_123.html#SEC125 (.skip)
.skip 40 - (. - record_1_first_name) # Add padding null so that we have 40 bytes.

.asciz "Gede"
# Repeat the sequence of line between .rept and .endr directive N times.
# References:
# - https://stackoverflow.com/a/74062053
# - https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_node/as_114.html#SEC116 (.rept)
# - https://stackoverflow.com/q/74725082 (.rept only accept number)
.rept 35 # Add padding null so that we have 40 bytes.
.byte 0
.endr

.asciz "4242 S Prairie\nTulsa, OK 55555"
.rept 209 # Add padding null so that we have 240 bytes.
.byte 0
.endr

# Looks like write() and read() only able to handle ASCII characters.
# So if we store this in a file, it will be the ASCII character of this number.
# References:
# - https://stackoverflow.com/q/36532752
# - https://stackoverflow.com/a/13166463
.long 45 # Age data.

record_2:
.asciz "Marilyn"
.rept 32
.byte 0
.endr

.asciz "Taylor"
.rept 33
.byte 0
.endr

.asciz "2224 S Johannan St\nChicago, IL 12345"
.rept 203
.byte 0
.endr

.long 42

record_3:
.asciz "Derrick"
.rept 32
.byte 0
.endr

.asciz "McIntire"
.rept 31
.byte 0
.endr

.asciz "500 W Oakland\nSan Diego, CA 54321"
.rept 206
.byte 0
.endr

.long 69

file_name:
.string "test.dat"

.equ ST_FD, -REG_SIZE
.equ ST_DEALLOC_ARGS, REG_SIZE + REG_SIZE

# No .text section in the book but we still can execute this?
# The only noticeable difference is when using `objdump -d`, which only show
# instructions on .text section (?).
.globl _start
_start:
movl %esp, %ebp

subl $REG_SIZE, %esp

movl $0644, %edx # 3rd argument.
movl $0101, %ecx # 0101 is an octal number for O_CREAT (0100) and O_WRONLY (0001).
movl $file_name, %ebx
movl $SYS_OPEN, %eax
int $LINUX_SYSCALL

movl %eax, ST_FD(%ebp) # Store file descriptor.

pushl ST_FD(%ebp)
pushl $record_1
call write_record
addl $ST_DEALLOC_ARGS, %esp

pushl ST_FD(%ebp)
pushl $record_2
call write_record
addl $ST_DEALLOC_ARGS, %esp

pushl ST_FD(%ebp)
pushl $record_3
call write_record
addl $ST_DEALLOC_ARGS, %esp

movl ST_FD(%ebp), %ebx
movl $SYS_CLOSE, %eax
int $LINUX_SYSCALL

movl $0, %ebx
movl $SYS_EXIT, %eax
int $LINUX_SYSCALL
