~\Downloads\nasm-2.14.02\nasm.exe .\boot.asm -o .\boot.bin
if (!$?) { exit }
$src = [System.IO.FileStream]::new((Get-Item .\boot.bin).FullName, [System.IO.FileMode]::Open)
$dst = [System.IO.FileStream]::new((Get-Item .\x86.vfd).FullName, [System.IO.FileMode]::Open)
$src.CopyTo($dst)
$src.Dispose()
$dst.Dispose()
