; DIR_Name      db      "FILENAMEEXT"
; DIR_Attr      db      0x20
;               db      0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; DIR_WrtTime   dw
; DIR_WrtDate   dw
; DIR_FstClus   dw
; DIR_FileSize  dd

FATTmpBase      equ     0x50
FATTmpOffset    equ     0

RootDirSecCnt   equ     14
RootDirFstSec   equ     19
RootDirEndSec   equ     RootDirFstSec + RootDirSecCnt
FATFstSec       equ     1

; (file name, base, offset; BPB_BytesPerSec, BPB_SecPerTrk, BS_DrvNum, not_found, loaded)
%macro  LOAD_FILE       3

        xor     ah, ah                  ; | AH = reset disk
        xor     dl, dl                  ; | DL = drive
        int     0x13                    ; |

        mov     dx, RootDirFstSec
.sector:
        cmp     dx, RootDirEndSec
        jge     .pre_not_found
        push    dx
        mov     ax, %2                  ; |
        mov     es, ax                  ; |
        mov     ax, dx                  ; |
        mov     bx, %3                  ; |
        mov     cl, 1                   ; |
        call    read_sector             ; |
        pop     dx

        mov     si, %1                  ; DS:SI = "LOADER  BIN"
        mov     di, %3                  ; ES:DI = LoaderBase:LoaderOffset
        cld                             ; string operations increment SI

        mov     cx, 0x10                ; BX = entries per sector = 512 / 32
.dir_entry:

        mov     bx, 11                  ; CX = length of DIR_Name
.file_name:
        lodsb
        cmp     al, byte [es:di]
        jnz     .next_dir_entry

        dec     bx
        test    bx, bx
        jz      .found

        inc     di
        jmp     .file_name

.next_dir_entry:
        dec     cx
        test    cx, cx
        jz      .next_sector

        mov     si, %1                  ; DS:SI = "LOADER  BIN"
        and     di, 0xffe0
        add     di, 0x20                ; size of directory entry
        jmp     .dir_entry

.next_sector:
        inc     dx
        jmp     .sector

.pre_not_found:
        jmp     not_found

.found:                                 ; (ES:DI)
        and     di, 0xffe0
        add     di, 0x1a                ; offset of DIR_FstClus
        mov     ax, word [es:di]
        push    ax                      ; AX = first cluster
        add     ax, RootDirEndSec - 2   ; AX = first sector

        mov     bx, %3

.loading:
        push    ax
        push    bx
        mov     ah, 0x0e                ; | AH = teletype output
        mov     al, '.'                 ; | AL = character
        xor     bx, bx                  ; | BH = page number, BL = color (unused)
        int     0x10                    ; |
        pop     bx
        pop     ax

        mov     cl, 1                   ; |
        call    read_sector             ; |

        pop     ax
        call    get_fat_entry
        cmp     ax, 0x0fff
        jz      .pre_loaded
        push    ax                      ; AX = cluster number
        add     ax, RootDirEndSec - 2   ; AX = sector number
        add     bx, [BPB_BytesPerSec]
        jmp     .loading

.pre_loaded:
        jmp     loaded

get_fat_entry:                          ; func (AX = cluster number) AX <- next cluster
        push    es
        push    bx

        mov     bx, 3
        mul     bx
        mov     bx, 2
        div     bx                      ; DX:AX = dividend => AX <- quotient = byte offset, DX <- remainder
        test    dx, dx
        setz    dl                      ; DL = is even
        push    dx

        xor     dx, dx
        div     word [BPB_BytesPerSec]  ; AX <- quotient = sector offset, DX <- remainder = byte offset
        push    dx

        mov     bx, FATTmpBase          ; |
        mov     es, bx                  ; |
        add     ax, FATFstSec           ; |
        mov     bx, FATTmpOffset        ; |
        mov     cl, 2                   ; |
        call    read_sector             ; |

        pop     dx                      ; DX = byte offset
        add     bx, dx
        mov     ax, [es:bx]

        pop     dx                      ; DL = is even
        test    dl, dl
        jnz     .even
        shr     ax, 4
.even:
        and     ax, 0x0fff

        pop     bx
        pop     es

        ret

; 2 (head) * 80 (cylinder) * 18 (sector) * 512B = 1474560B = 1.44MB
read_sector:                            ; func (AX = sector number >= 0, ES:BX = buffer address, CL = sector count)
        push    cx

        div     byte [BPB_SecPerTrk]    ; AX = dividend => AL <- quotient, AH <- remainder
        mov     ch, al                  ; CH = cylinder = quotient >> 1
        shr     ch, 1
        mov     cl, ah                  ; CL = sector = remainder + 1
        inc     cl
        mov     dh, al                  ; DH = head = quotient & 1
        and     dh, 1

        pop     ax                      ; AL = sector count
        mov     ah, 0x02                ; AH = read sectors
        mov     dl, [BS_DrvNum]         ; DL = drive
        int     0x13                    ; ES:BX = buffer address

        ret

%endmacro
