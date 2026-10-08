# Copy string using movsb instruction.
#
# References:
# - https://chessman7.substack.com/p/why-you-cant-directly-move-data-between
# - https://github.com/cirosantilli/x86-assembly-cheat/blob/ba3b76cd4530268d4c34e29c354d399c0d8552fc/ia-32/movs.asm
# - https://stackoverflow.com/questions/70734233/rep-movsb-for-overlapped-memory

.include "common/linux-common.s"
.include "common/linux-x86-64.s"

.section .rodata
message:
.asciz "  Some messages\n"
.equ message_len, (. - message)

.section .bss
.lcomm msg_buffer, message_len

.section .text
.globl _start
_start:
movq %rsp, %rbp

movq $message, %rsi # Source address.
movq $msg_buffer, %rdi # Destination address.
movl $message_len, %ecx # Total bytes.
cld
rep movsb

# Try moving string without leading space.
movq $(msg_buffer + 2), %rsi # Source address.
movq $msg_buffer, %rdi # Destination address.
movl $message_len, %ecx # Total bytes.
cld
rep movsb # Repeat until counter equal %rcx value - 1 (?).

movl $message_len, %edx
movq $msg_buffer, %rsi
movl $1, %edi
movl $SYS_WRITE, %eax
syscall

movl $0, %edi
movl $SYS_EXIT, %eax
syscall
