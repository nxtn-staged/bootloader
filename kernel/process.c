// #include "regs.h"

#include "int.h"

const u64_t STACK_TOP = 0x7c00;
const u64_t STACK_SIZE = 0x1000;

struct process_t
{
    // struct regs_t regs;

    u64_t rsp0;

    u64_t rsp;
    u64_t rip;
};

struct __attribute__((packed)) tss_t
{
    u32_t reserved0;
    u64_t rsp0;
    u64_t rsp1;
    u64_t rsp2;
    u64_t reserved1;
    u64_t ist1;
    u64_t ist2;
    u64_t ist3;
    u64_t ist4;
    u64_t ist5;
    u64_t ist6;
    u64_t ist7;
    u64_t reserved2;
    u16_t reserved3;
    u16_t iobase;
};

struct tss_t tss =
{
    .reserved0 = 0,
    .rsp0 = 0,
    .rsp1 = 0,
    .rsp2 = 0,
    .reserved1 = 0,
    .ist1 = STACK_TOP,
    .ist2 = STACK_TOP,
    .ist3 = STACK_TOP,
    .ist4 = STACK_TOP,
    .ist5 = STACK_TOP,
    .ist6 = STACK_TOP,
    .ist7 = STACK_TOP,
    .reserved2 = 0,
    .reserved3 = 0,
    .iobase = 0,
};

/*inline*/ struct process_t* get_current_process()
{
    struct process_t* current;
    asm("and     %0, rsp" : "=r" (current) : "0" (0x1234));
    return current;
}

/*inline*/ void switch_to_process(struct process_t* prev, struct process_t* next) 
{
    asm(
        "mov     %0, rsp;"
        "mov     rsp, %2;"
        "mov     %1, end;"
        "jmp     %3;"
        : "=m" (prev->rsp), "=m" (prev->rip)
        : "m" (next->rsp), "m" (next->rip)
    );

end:
    return;
}
