void initialize_wtf(void)
{
    wrmsr(IA32_SYSENTER_CS, SEL_KERNEL_CS);
    wrmsr(IA32_SYSENTER_ESP, );
    wrmsr(IA32_SYSENTER_EIP, );
}

void system_call2(struct regs_t* regs)
{

}
