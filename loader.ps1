~\Downloads\nasm-2.14.02\nasm.exe .\loader.asm -o .\loader.bin
if (!$?) { exit }
$src = [System.IO.FileStream]::new((Get-Item .\loader.bin).FullName, [System.IO.FileMode]::Open)
if ($src.Length -gt 0x400) {
    $src.Dispose()
    Write-Error 'too large'
    exit
}
$dst = [System.IO.FileStream]::new((Get-Item .\x86.vfd).FullName, [System.IO.FileMode]::Open)
$dst.Position = 0x4200
$src.CopyTo($dst)
$src.Dispose()
$dst.Dispose()
