#include "int.h"

const u64_t IA32_SYSENTER_CS = 0x174;
const u64_t IA32_SYSENTER_ESP = 0x175;
const u64_t IA32_SYSENTER_EIP = 0x176;

inline void wrmsr(u64_t address, u64_t value)
{
    asm("wrmsr" :: "d" (address >> 32), "a" (address), "c" (value));
}
