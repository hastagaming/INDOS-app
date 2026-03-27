#!/bin/bash

# Warna Neon INDOS
C="\e[1;36m"; G="\e[1;32m"; W="\e[1;37m"; R="\e[0m"; Y="\e[1;33m"

clear
echo -e "${C}─────────────────────────────────────${R}"
echo -e "${G}     INSTALASI INDOS NATIVE (V3.7)${R}"
echo -e "${C}─────────────────────────────────────${R}"

# Fungsi Sinkronisasi GitHub (Hanya untuk Pemilik: hastagaming)
git_sync() {
    if [ -d ".git" ]; then
        REMOTE_URL=$(git config --get remote.origin.url)
        if [[ "$REMOTE_URL" == *"hastagaming"* ]]; then
            echo -e "\n${Y}[*] Mendeteksi Pemilik: Sinkronisasi GitHub...${R}"
            git add .
            git commit -m "V3.7: Fix Rootfs Path & Profile Sync: $(date +'%Y-%m-%d %H:%M')" 2>/dev/null
            
            echo -e "${C}[>] Rebase & Push...${R}"
            if ! git pull --rebase origin main 2>/dev/null; then
                git add .
                git rebase --continue 2>/dev/null || git rebase --skip
            fi
            git push origin main 2>/dev/null
            echo -e "${G}[+] GitHub Diperbarui!${R}"
        fi
    fi
}

install_indos() {
    echo -e "\n${Y}[*] Memasang biner PRoot terbaru...${R}"
    pkg install proot -y > /dev/null 2>&1
    
    if [ ! -d "$HOME/storage" ]; then
        termux-setup-storage
        sleep 2
    fi

    # SESUAI PERINTAH: Menggunakan nama folder 'rootfs'
    TARGET="$HOME/INDOS/rootfs"
    TMP_PRoot="$HOME/.proot-tmp"
    
    echo -e "${Y}[*] Membangun sistem INDOS di $TARGET...${R}"
    # Kita tidak hapus seluruh folder agar file profile buatanmu aman, 
    # kita hanya pastikan struktur folder penting ada.
    mkdir -p $TARGET/bin $TARGET/etc $TARGET/root $TARGET/tmp $TARGET/sdcard
    mkdir -p $TMP_PRoot
    
    # 1. PASANG MESIN (Busybox sebagai Shell)
    cp $PREFIX/bin/busybox $TARGET/bin/sh
    chmod 755 $TARGET/bin/sh
    
    # 2. IDENTITAS & PASSWORD
    echo "root:x:0:0:root:/root:/bin/sh" > $TARGET/etc/passwd
    echo "root:x:0:" > $TARGET/etc/group

    # 3. SINKRONISASI PROFILE (Mencari file 'profile' di folder ~/INDOS/)
    if [ -f "$HOME/INDOS/profile" ]; then
        echo -e "${Y}[*] Memasang file profile NASA ke $TARGET/etc/profile...${R}"
        cp $HOME/INDOS/profile $TARGET/etc/profile
    else
        echo -e "${R}[!] PERINGATAN: File 'profile' tidak ditemukan di ~/INDOS/!${R}"
    fi

    echo -e "${Y}[*] Merakit Kernel Peluncur Bersih (Android 15 Fix)...${R}"
    cat << 'INNER_EOF' > $PREFIX/bin/indos
#!/bin/bash
clear
unset LD_PRELOAD

# Pengaturan TMP untuk Realme Note 50
export TMPDIR=$HOME/.proot-tmp
export PROOT_TMP_DIR=$HOME/.proot-tmp
export PROOT_NO_SECCOMP=1

# JALANKAN PROOT:
# Target diubah ke folder 'rootfs'
# Tanpa /linkerconfig untuk menghilangkan Warning
proot -0 \
      -r $HOME/INDOS/rootfs \
      -b /dev \
      -b /proc \
      -b /sys \
      -b /system \
      -b /apex \
      -b /vendor \
      -b /sdcard \
      -b $PREFIX \
      -w / \
      /bin/sh -c "export HOME=/root; export USER=root; export PATH=/bin:/usr/bin:/sbin; exec /bin/sh -l"
INNER_EOF
    
    chmod +x $PREFIX/bin/indos
    echo -e "${G}[+] INDOS NATIVE V3.7 BERHASIL TERPASANG!${R}"
    
    git_sync
}

# Menu Interaktif
echo -e "${W}Apakah kamu mau tutorial?${R}"
echo -e "${G}1)${W} Iya"
echo -e "${R}2)${W} Tidak"
echo -ne "\n${Y}Pilih (1/2): ${R}"
read choice

if [ "$choice" == "1" ]; then
    clear
    echo -e "${G}─── TUTORIAL INDOS ───${R}"
    echo -e "${W}1. Ketik ${G}'indos'${W} untuk masuk."
    echo -e "2. Rootfs berada di ${C}~/INDOS/rootfs${W}."
    echo -e "3. Profile dipanggil otomatis dari ${C}/etc/profile${W}."
    echo -e "${C}──────────────────────${R}"
    sleep 3
fi

install_indos

echo -e "\n${C}─────────────────────────────────────${R}"
echo -e "${W}Ketik ${G}\"indos\"${W} untuk memulai distronya${R}"
echo -e "${C}─────────────────────────────────────${R}"
