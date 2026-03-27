#!/bin/bash

# Warna Neon INDOS
C="\e[1;36m"; G="\e[1;32m"; W="\e[1;37m"; R="\e[0m"; Y="\e[1;33m"

clear
echo -e "${C}─────────────────────────────────────${R}"
echo -e "${G}      INDOS OS - AUTO BUILDER V1.3${R}"
echo -e "${C}─────────────────────────────────────${R}"

# 1. Pastikan Alat Tempur Terpasang
echo -e "${Y}[*] Memeriksa compiler & tools...${R}"
pkg install clang binutils xorriso qemu-utils nasm -y > /dev/null 2>&1
[ ! -f "$PREFIX/bin/gcc" ] && ln -s "$PREFIX/bin/clang" "$PREFIX/bin/gcc"

# 2. Merakit Bootloader (boot.asm) dengan Stack Setup
echo -e "${Y}[*] Merakit Bootloader (boot.asm)...${R}"
cat << 'A_EOF' > boot.asm
[bits 16]
[org 0x7c00]

start:
    ; Setup segment & stack agar stabil di Android 15
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    mov si, msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0e
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

msg db 'INDOS OS LOADING...', 13, 10, 'Welcome Nasa (hastagaming)!', 0

times 510-($-$$) db 0
dw 0xaa55
A_EOF

# 3. Siapkan Kode Kernel C
if [ ! -f "kernel.c" ]; then
    echo -e "${Y}[*] Membuat kernel.c INDOS...${R}"
    cat << 'K_EOF' > kernel.c
void main() {
    char *video_memory = (char*) 0xb8000;
    *video_memory = 'I'; 
}
K_EOF
fi

# 4. Proses Kompilasi & Linker
echo -e "${Y}[*] Mengompilasi Bootloader...${R}"
nasm -f bin boot.asm -o boot.bin

echo -e "${Y}[*] Mengompilasi Kernel INDOS...${R}"
gcc -ffreestanding -fno-stack-protector -c kernel.c -o kernel.o
ld -o kernel.bin -Ttext 0x1000 --image-base 0x0 kernel.o --oformat binary

# Buat file Image murni (Floppy 1.44MB style agar Limbo mau baca)
cat boot.bin kernel.bin > INDOS.img
truncate -s 1440k INDOS.img

# 5. Merakit INDOS.iso (Metode El Torito Bootable)
echo -e "${Y}[*] Merakit INDOS.iso...${R}"
mkdir -p iso_root
cp INDOS.img iso_root/
xorrisofs -o INDOS.iso \
    -b INDOS.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    iso_root/ > /dev/null 2>&1

# 6. Membuat INDOS.qcow2
if [ ! -f "INDOS.qcow2" ]; then
    echo -e "${Y}[*] Membuat Hardisk Virtual INDOS 512MB...${R}"
    qemu-img create -f qcow2 INDOS.qcow2 512M > /dev/null 2>&1
fi

# 7. Auto-Copy ke Download (Khusus untuk HP Nasa)
cp INDOS.iso /sdcard/Download/ 2>/dev/null
cp INDOS.qcow2 /sdcard/Download/ 2>/dev/null

# 8. Kirim Hasil ke GitHub (Hanya untuk hastagaming)
git_upload() {
    if [ -d ".git" ]; then
        REMOTE_URL=$(git config --get remote.origin.url)
        if [[ "$REMOTE_URL" == *"hastagaming"* ]]; then
            echo -e "\n${Y}[*] Mengunggah INDOS ke GitHub Cloud...${R}"
            git add INDOS.iso INDOS.qcow2 boot.asm kernel.c
            git commit -m "Build V1.3: Fix No Bootable Device $(date +'%Y-%m-%d %H:%M')" 2>/dev/null
            git push origin main
            echo -e "${G}[+] GitHub Berhasil Diperbarui!${R}"
        fi
    fi
}

echo -e "${C}─────────────────────────────────────${R}"
echo -e "${G}[+] BUILD SELESAI!${R}"
echo -e "${W}File dikirim ke: ${C}/sdcard/Download/${R}"
echo -e "${C}─────────────────────────────────────${R}"

git_upload
