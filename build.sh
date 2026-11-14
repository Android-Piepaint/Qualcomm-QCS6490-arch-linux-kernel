#!/usr/bin/env bash
# Runs INSIDE the Arch Linux ARM container. /work = repo checkout (with ./linux cloned).
set -euo pipefail
cd /work

# Docker-friendly pacman settings
sed -i 's/^CheckSpace/#CheckSpace/' /etc/pacman.conf
if pacman -S --help | grep -q -- '--disable-sandbox'; then
  sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf
fi

pacman-key --init
pacman-key --populate archlinuxarm
pacman -Syu --noconfirm --needed base-devel git bc cpio pahole python perl xz zstd kmod

id builder &>/dev/null || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
chown -R builder:builder /work

su builder -c 'cd /work/pkg && KSRC=/work/linux MAKEFLAGS="-j$(nproc)" PKGDEST=/work/repo makepkg -f --noconfirm --skippgpcheck'

cd /work/repo
rm -f sc7280.db* sc7280.files*
repo-add sc7280.db.tar.zst ./*.pkg.tar.zst
ls -lh /work/repo
