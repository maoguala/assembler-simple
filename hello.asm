section .data
    msg db "Hello", 0
    msg_len equ 5

section .bss
    written resd 1

section .text
    global _main
    extern GetStdHandle
    extern WriteConsoleA
    extern ExitProcess

_main:
    ; Get stdout handle
    mov rcx, -11
    call GetStdHandle

    ; WriteConsoleA(handle, msg, len, &written, NULL)
    mov rcx, rax
    lea rdx, [rel msg]
    mov r8, msg_len
    lea r9, [rel written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; ExitProcess(0)
    xor rcx, rcx
    call ExitProcess