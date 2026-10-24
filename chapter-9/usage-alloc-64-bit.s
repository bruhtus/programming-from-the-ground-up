.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-64.s"

.section .rodata
file_name:
.asciz "test.dat"
newline_char:
.ascii "\n"

.section .data
record_buffer_ptr:
.quad 0
reusable_buffer_ptr:
.quad 0

.equ ST_FD, REG_SIZE + REG_SIZE
.equ ST_INPUT_FD, -REG_SIZE
.equ ST_OUTPUT_FD, -(REG_SIZE + REG_SIZE)

.section .text
.globl _start
_start:
movq %rsp, %rbp

subq $ST_FD, %rsp

movl $0444, %edx # 3rd argument.
movl $0, %esi # 0 is for O_RDONLY.
movq $file_name, %rdi
movl $SYS_OPEN, %eax
syscall

movl %eax, ST_INPUT_FD(%rbp)
movl $STDOUT, ST_OUTPUT_FD(%rbp)

movl $RECORD_SIZE, %edi
call alloc

cmpq $0, %rax
je alloc_err

movq %rax, record_buffer_ptr

record_read_loop:
movl $RECORD_SIZE, %edx # 3rd argument.
movq record_buffer_ptr, %rsi
movl ST_INPUT_FD(%rbp), %edi
movl $SYS_READ, %eax
syscall

# If the read_record return value is not the same as RECORD_SIZE,
# it is either we got end of file (EOF) or error.
cmpl $RECORD_SIZE, %eax
jne record_read_end

allocate_for_address:
movl $RECORD_ADDRESS_SIZE, %edi
call alloc

cmpq $0, %rax
je alloc_err

movq %rax, reusable_buffer_ptr

movq record_buffer_ptr, %rsi # Source address.
addq $RECORD_ADDRESS, %rsi
movq reusable_buffer_ptr, %rdi # Destination address.
movl $RECORD_ADDRESS_SIZE, %ecx # Total bytes to copy.
cld
rep movsb # Copy memory until counter equal %rcx value - 1 (?).

movl $RECORD_ADDRESS_SIZE, %edx # 3rd argument.
movq reusable_buffer_ptr, %rsi
movl ST_OUTPUT_FD(%rbp), %edi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl write_err

movl $1, %edx # 3rd argument.
movq $newline_char, %rsi
movl ST_OUTPUT_FD(%rbp), %edi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl write_err

movq reusable_buffer_ptr, %rdi
call dealloc
movl $0, reusable_buffer_ptr # Set the pointer to null.

allocate_for_first_name:
movl $RECORD_FIRST_NAME_SIZE, %edi
call alloc

cmpq $0, %rax
je alloc_err

movq %rax, reusable_buffer_ptr

movq record_buffer_ptr, %rsi # Source address.
addq $RECORD_FIRST_NAME, %rsi
movq reusable_buffer_ptr, %rdi # Destination address.
movl $RECORD_FIRST_NAME_SIZE, %ecx # Total bytes to copy.
cld
rep movsb # Copy memory until counter equal %rcx value - 1 (?).

movl $RECORD_FIRST_NAME_SIZE, %edx # 3rd argument.
movq reusable_buffer_ptr, %rsi
movl ST_OUTPUT_FD(%rbp), %edi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl write_err

movl $1, %edx # 3rd argument.
movq $newline_char, %rsi
movl ST_OUTPUT_FD(%rbp), %edi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl write_err

movq reusable_buffer_ptr, %rdi
call dealloc
movl $0, reusable_buffer_ptr # Set the pointer to null.

jmp record_read_end

alloc_err:
movl $69, %edi
jmp record_exit

write_err:
movl $42, %edi
jmp cleanup

record_read_end:
movl $0, %edi
jmp cleanup

cleanup:
pushq %rdi
movq record_buffer_ptr, %rdi
call dealloc
popq %rdi
jmp record_exit

record_exit:
movl $SYS_EXIT, %eax
syscall
