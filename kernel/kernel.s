.global _start

_start:

        lgdt    [rip + GDT_PTR]
        lidt    [rip + IDT_PTR]
        ret

GDT:            .quad   0x0000000000000000
DESC_KERNEL_CS: .quad   0x00209a0000000000      # DPL = 0
DESC_KERNEL_DS: .quad   0x0000920000000000      # DPL = 0
DESC_USER_CS:   .quad   0x0020fa0000000000      # DPL = 3
DESC_USER_DS:   .quad   0x0000f20000000000      # DPL = 3
GDT_END:

GDT_PTR:        .word   GDT_END - GDT - 1
                .quad   GDT

SEL_KERNEL_CS   .equ    DESC_KERNEL_CS - GDT
SEL_KERNEL_DS   .equ    DESC_KERNEL_DS - GDT
SEL_USER_CS     .equ    DESC_USER_CS - GDT
SEL_USER_DS     .equ    DESC_USER_DS - GDT

IDT:
IDT_END:

IDT_PTR:        .word   IDT_END - IDT - 1
                .quad   IDT

TSS:
TSS_END:

TSS_PTR:        .word   TSS_END - TSS - 1
                .quad   TSS

system_call:
        push    rax
        push    rbx
        push    rcx
        push    rdx
        push    rsi
        push    rdi
        push    rbp
        push    r8
        push    r9
        push    r10
        push    r11
        push    r12
        push    r13
        push    r14
        push    r15

        mov     rdi, rsp

return_from_system_call:
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     r11
        pop     r10
        pop     r9
        pop     r8
        pop     rbp
        pop     rdi
        pop     rsi
        pop     rdx
        pop     rcx
        pop     rbx
        pop     rax
