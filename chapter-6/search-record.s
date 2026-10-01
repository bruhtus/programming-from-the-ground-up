# Search record data with 5 characters as its input and return any data that
# start with those 5 characters.

.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-64.s"

.section .rodata
newline_char:
.ascii "\n"
space_char:
.ascii " "
file_name:
.asciz "test-append.dat"
.equ file_name_len, (. - file_name)
open_err_msg:
.asciz "Failed to open file\n"
.equ open_err_msg_len, (. - open_err_msg)
read_input_err_msg:
.asciz "Failed to read input (possibly input exceed characters limit)\n"
.equ read_input_err_msg_len, (. - read_input_err_msg)
input_required_err_msg:
.asciz "Input can not be empty\n"
.equ input_required_err_msg_len, (. - input_required_err_msg)
read_data_err_msg:
.asciz "Failed to read data\n"
.equ read_data_err_msg_len, (. - read_data_err_msg)

.equ INPUT_SEARCH_SIZE, 6 # 5 characters + 1 enter character.

.section .bss
.lcomm record_buffer, RECORD_SIZE
.lcomm input_search, INPUT_SEARCH_SIZE

.section .text
.globl _start
_start:
movq %rsp, %rbp

movl $0444, %edx
movl $0, %esi # O_RDONLY.
movq $file_name, %rdi
movl $SYS_OPEN, %eax
syscall

cmpl $0, %eax
jl prepare_open_err

pushq %rax
.equ OPEN_FD, REG_SIZE

read_input_search:
movl $INPUT_SEARCH_SIZE, %esi
movq $input_search, %rdi
call read_stdin

cmpl $EOF, %eax
jl prepare_read_input_err
je prepare_input_required_err

.equ DATA_SCOPE, (record_buffer + RECORD_FIRST_NAME)

read_record_begin:
movl $RECORD_SIZE, %edx
movq $record_buffer, %rsi
movl -OPEN_FD(%rbp), %edi
movl $SYS_READ, %eax
syscall

# If the read_record return value is not the same as RECORD_SIZE,
# it is either we got end of file (EOF) or error.
cmpl $RECORD_SIZE, %eax
jne read_record_end

movq $DATA_SCOPE, %rsi
movq $input_search, %rdi
call search_record

cmpl $0, %eax
jl read_record_begin

movl $RECORD_FIRST_NAME_SIZE, %edx
movq $(record_buffer + RECORD_FIRST_NAME), %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

movl $1, %edx
movq $space_char, %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

movl $RECORD_LAST_NAME_SIZE, %edx
movq $(record_buffer + RECORD_LAST_NAME), %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

movl $1, %edx
movq $space_char, %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

movl $RECORD_ADDRESS_SIZE, %edx
movq $(record_buffer + RECORD_ADDRESS), %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

movl $1, %edx
movq $newline_char, %rsi
movl $STDOUT, %edi
movl $SYS_WRITE, %eax
syscall

jmp read_record_begin

read_record_end:
movl %eax, %ebx

cmpl $0, %ebx
jl prepare_read_data_err

close_file:
movl -OPEN_FD(%rbp), %edi
movl $SYS_CLOSE, %eax
syscall

movl $0, %edi
movl $SYS_EXIT, %eax
syscall

prepare_open_err:
movl %eax, %ebx

movl $open_err_msg_len, %edx
movl $open_err_msg, %esi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

jmp exit_err

prepare_input_required_err:
movl $input_required_err_msg_len, %edx
movl $input_required_err_msg, %esi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

movl $1, %ebx
jmp exit_err

prepare_read_input_err:
# Get rid excess characters in standard input.
# Reference:
# https://web.archive.org/web/20170322030422/http://www.dreamincode.net/forums/topic/286248-nasm-linux-terminal-inputoutput-wint-80h/
movl $1, %edx
movq $(input_search + INPUT_SEARCH_SIZE - 1), %rsi # Why we can not use the first byte of input_search?
movl $STDIN, %edi
movl $SYS_READ, %eax
syscall

cmpl $10, (input_search + INPUT_SEARCH_SIZE - 1)
jne prepare_read_input_err

print_read_input_err:
movl $read_input_err_msg_len, %edx
movl $read_input_err_msg, %esi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

movl $1, %ebx
jmp exit_err

prepare_read_data_err:
movl $read_data_err_msg_len, %edx
movl $read_data_err_msg, %esi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

jmp exit_err # Expected %rbx value already been set.

exit_err:
movl -OPEN_FD(%rbp), %edi
movl $SYS_CLOSE, %eax
syscall

movl %ebx, %edi
movl $SYS_EXIT, %eax
syscall

# - %rdi: the start of buffer address.
# - %rsi: the input size.
read_stdin:
pushq %rbp
movq %rsp, %rbp

movl %esi, %edx
movq %rdi, %rsi
movl $STDIN, %edi
movl $SYS_READ, %eax
syscall

cmpl $EOF, %eax
jle read_stdin_end

decl %eax
movb (%esi,%eax,1), %r10b # Looks like we can use 32-bit register format in indirect addressing mode?

# Maybe we can use the last character on the buffer as
# indicator that the input exceed the buffer size?
cmpl $10, %r10d
je read_stdin_end

# Looks like we can provide negative immediate value?
movl $-10, %eax

read_stdin_end:
movq %rbp, %rsp
popq %rbp
ret

# - %rdi: the start of input buffer address.
# - %rsi: the start of record buffer address.
#
# The search mechanism is check if the first character is the same or not,
# and then keep going to compare the next character. The search is kind of using
# a substring mechanism but start from the beginning instead of arbitrary
# location.
search_record:
pushq %rbp
movq %rsp, %rbp

movl $0, %eax # Search match indicator.

search_record_begin:
# To mitigate x86 limitation that can not do operation between memory address
# directly (?).
movb (%rdi), %r10b

cmpb %r10b, (%rsi)
jne search_not_match

incl %edi
incl %esi

cmpb $10, (%rdi) # Check the enter character at the end of input buffer.
je search_record_end

jmp search_record_begin

search_not_match:
movl $-1, %eax

search_record_end:
movq %rbp, %rsp
popq %rbp
ret
