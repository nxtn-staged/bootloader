StackOffset     org     0x7c00

LoaderBase      equ     0x07e0  ; arbitrary
LoaderOffset    equ     0x0000  ; 2 sectors for FAT

BS_jmpBoot      jmp     boot
                nop
BS_OEMName      db      "NoMoney "
BPB_BytesPerSec dw      512
BPB_SecPerClus  db      1
BPB_RsvdSecCnt  dw      1
BPB_NumFATs     db      2
BPB_RootEntCnt  dw      224
BPB_TotSec16    dw      2880
BPB_Media       db      0xf0
BPB_FATSz16     dw      9
BPB_SecPerTrk   dw      18
BPB_NumHeads    dw      2
BPB_HiddSec     dd      0
BPB_TotSec32    dd      0
BS_DrvNum       db      0
BS_Reserved1    db      0
BS_BootSig      db      0x29
BS_VolID        dd      0
BS_VolLab       db      "NoMoneyOS  "
BS_FileSysType  db      "FAT12   "

boot:
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, StackOffset

        mov     bp, BootMsg     ; | ES:BP = string address
        mov     ax, 0x1301      ; | AH = write string, AL = write mode (attribute in BL; update cursor)
        mov     bx, 0x000f      ; | BH = page number, BL = color (white foreground, black background)
        mov     cx, BootMsgLen  ; | CX = string length
        mov     dx, 0           ; | DH = row, DL = column
        int     0x10            ; |

%include "fat12.inc"

        push    es
        LOAD_FILE LoaderFileName, LoaderBase, LoaderOffset

not_found:
        pop     es
        mov     bp, FailMsg     ; ES:BP = string address
        mov     ax, 0x1301      ; AH = write string, AL = write mode (attribute in BL; update cursor)
        mov     bx, 0x000f      ; BH = page number, BL = color (white foreground, black background)
        mov     cx, FailMsgLen  ; CX = string length
        mov     dh, 0           ; DH = row
        mov     dl, BootMsgLen  ; DL = column
        int     0x10
.hlt:
        hlt
        jmp     .hlt

loaded:
        pop     es
        jmp     LoaderBase:LoaderOffset

LoaderFileName  db      "LOADER  BIN"
BootMsg         db      "Booting"
BootMsgLen      equ     7
FailMsg         db      " :("
FailMsgLen      equ     3

        times   510 - ($ - $$)  db      0
        dw      0xaa55
