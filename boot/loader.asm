        org     0x7e00

StackOffset     equ     0x7c00

KernelTmpBase   equ     0x3000
KernelTmpOffset equ     0

KernelBase      equ     0x4000
KernelAddr      equ     0x40000

PageTableAddr   equ     0x90000

        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, StackOffset

        mov     bp, LoadMsg     ; | ES:BP = string address
        mov     ax, 0x1301      ; | AH = write string, AL = write mode (attribute in BL; update cursor)
        mov     bx, 0x000f      ; | BH = page number, BL = color (white foreground, black background)
        mov     cx, LoadMsgLen  ; | CX = string length
        mov     dx, 0x0100      ; | DH = row, DL = column
        int     0x10            ; |

%include "fat12.inc"

        push    es
        LOAD_FILE KernelFileName, KernelTmpBase, KernelTmpOffset

not_found:
        pop     es
        mov     bp, FailMsg     ; ES:BP = string address
        mov     ax, 0x1301      ; AH = write string, AL = write mode (attribute in BL; update cursor)
        mov     bx, 0x000f      ; BH = page number, BL = color (white foreground, black background)
        mov     cx, FailMsgLen  ; CX = string length
        mov     dh, 1           ; DH = row
        mov     dl, LoadMsgLen  ; DL = column
        int     0x10
.hlt:
        hlt
        jmp     .hlt

loaded:
        pop     es

        mov     dx, 0x3f2       ; | digital control port
        mov     al, 0           ; |
        out     dx, al          ; |

        mov     ax, KernelTmpBase
        mov     es, ax
        mov     ax, KernelBase
        mov     fs, ax
        ; mov     di, [es:0x2c]   ; Elf32_Ehdr.e_phnum
        ; mov     bx, [es:0x1c]   ; Elf32_Ehdr.e_phoff
        mov     dx, [es:0x38]   ; Elf64_Ehdr.e_phnum
        mov     bx, [es:0x20]   ; Elf64_Ehdr.e_phoff
.phdr:
        test    dx, dx
        jz      .copied
        dec     dx

        mov     cx, [es:bx]     ; CX = Elf64_Phdr.p_type
        cmp     cx, 1           ; LOAD
        jne     .next_phdr

        ; mov     si, [es:bx + 0x4]       ; SI = src = Elf32_Phdr.p_offset
        ; mov     di, [es:bx + 0x8]       ; DI = dst = Elf32_Phdr.p_vaddr
        ; mov     cx, [es:bx + 0x10]      ; CX = size = Elf32_Phdr.p_filesz
        mov     si, [es:bx + 0x8]       ; SI = src = Elf64_Phdr.p_offset
        mov     di, [es:bx + 0x10]      ; EDI = dst = Elf64_Phdr.p_vaddr
        mov     cx, [es:bx + 0x20]      ; CX = size = Elf64_Phdr.p_filesz

.copy:
        test    cx, cx
        jz      .next_phdr
        sub     cx, 1

        mov     al, [es:si]
        add     si, 1
        mov     [fs:di], al
        add     di, 1
        jmp     .copy

.next_phdr:
        ; add     bx, 0x20        ; Elf32_Ehdr.e_phentsize
        add     bx, 0x38        ; Elf64_Ehdr.e_phentsize
        jmp     .phdr

.copied:
        in      al, 0x92        ; | Fast Gate A20
        or      al, 0b10        ; |
        out     0x92, al        ; |

        cli

        lgdt    [GDT_PTR32]

        mov     eax, cr0        ; |
        bts     eax, 0          ; | PE (Protected Mode Enable)
        mov     cr0, eax        ; |

        jmp     dword SEL_CODE32:loader32

[bits 32]
loader32:
        mov     ax, SEL_DATA32
        mov     ds, ax

        ; PML4E (Page Map Level 4 Table Entry)
        ; P = 1, R/W = 1, U/S = 1
        ; [31:12] = PML4 base address
        mov     dword [PageTableAddr],          0x00091007

        ; PDPTE (Page Directory Pointer Table Entry)
        ; P = 1, R/W = 1, U/S = 1
        ; [31:12] = Page Directory base address
        mov     dword [PageTableAddr + 0x1000], 0x00092007

        ; PDE (Page Directory Entry)
        ; P = 1, R/W = 1, U/S = 1, 1 = 1
        ; [31:12] = Page Table base address
        mov     dword [PageTableAddr + 0x2000], 0x00000087
        mov     dword [PageTableAddr + 0x2008], 0x00200087
        mov     dword [PageTableAddr + 0x2010], 0x00400087
        mov     dword [PageTableAddr + 0x2018], 0x00600087
        mov     dword [PageTableAddr + 0x2020], 0x00800087
        mov     dword [PageTableAddr + 0x2028], 0x00a00087

        lgdt    [GDT_PTR64]

        mov     eax, cr4        ; |
        bts     eax, 5          ; | PAE (Physical Address Extension)
        mov     cr4, eax        ; |

        mov     eax, PageTableAddr
        mov     cr3, eax

        mov     ecx, 0xc0000080 ; | IA32_EFER
        rdmsr                   ; |
        bts     eax, 8          ; | LME (Long Mode Enable)
        wrmsr                   ; |

        mov     eax, cr0        ; |
        bts     eax, 31         ; | PG (Paging)
        mov     cr0, eax        ; |

        jmp     SEL_CODE64:loader64

loader64:
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax

        mov     ax, SEL_DATA64
        mov     ss, ax

        jmp     KernelAddr

BPB_BytesPerSec dw      512
BPB_SecPerTrk   dw      18
BS_DrvNum       db      0

KernelFileName  db      "KERNEL  BIN"
LoadMsg         db      "Loading"
LoadMsgLen      equ     7
FailMsg         db      " :("
FailMsgLen      equ     3

GDT32           dd      0, 0

DESC_CODE32     dw      0xffff          ; limit 0-15
                dw      0               ; base 0-15
                db      0               ; base 16-23
                db      0b10011010      ; type = read/execute, S = 1, DPL = 0, P = 1
                db      0b11001111      ; limit 16-19, D = 1, G = 1
                db      0               ; base 24-31

DESC_DATA32     dw      0xffff          ; limit 0-15
                dw      0               ; base 0-15
                db      0               ; base 16-23
                db      0b10010010      ; type = read/write, S = 1, DPL = 0, P = 1
                db      0b11001111      ; limit 16-19, D = 1, G = 1
                db      0               ; base 24-31

GDT_LEN32       equ     $ - GDT32
GDT_PTR32       dw      GDT_LEN32 - 1   ; limit
                dd      GDT32           ; base

SEL_CODE32      equ     DESC_CODE32 - GDT32
SEL_DATA32      equ     DESC_DATA32 - GDT32

GDT64           dd      0, 0
DESC_CODE64     dd      0, 0x00209a00   ; L = 1, D = 0
DESC_DATA64     dd      0, 0x00009200

GDT_LEN64       equ     $ - GDT64
GDT_PTR64       dw      GDT_LEN64 - 1
                dq      GDT64

SEL_CODE64      equ     DESC_CODE64 - GDT64
SEL_DATA64      equ     DESC_DATA64 - GDT64
