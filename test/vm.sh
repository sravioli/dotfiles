#!/bin/sh
# CachyOS test VM for the dotfiles. Disk images live in $VM_DIR (default ~/vms), outside the repo.
#   test/vm.sh install  download the newest ISO if needed and install CachyOS onto base.qcow2
#                       (power the VM off when the installer finishes)
#   test/vm.sh base     boot base.qcow2 itself; changes stick (e.g. add the dotfiles mount to fstab)
#   test/vm.sh          boot a throwaway copy of base.qcow2: a fresh install on every run
# The repo is shared read-only as 9p tag "dotfiles", so the VM sees uncommitted changes too:
#   sudo mount -t 9p -o trans=virtio,ro dotfiles /mnt
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
VM_DIR=${VM_DIR:-$HOME/vms}
mirror=https://mirror.cachyos.org/ISO/desktop
mkdir -p "$VM_DIR"; cd "$VM_DIR"
cdrom=""

case ${1:-run} in
  install)
    [ ! -e base.qcow2 ] || { echo "base.qcow2 already exists; delete it and base-vars.fd to reinstall"; exit 1; }
    ver=$(curl -fsSL "$mirror/" | grep -oE 'href="[0-9]{6}/' | grep -oE '[0-9]{6}' | sort -n | tail -1)
    [ -n "$ver" ] || { echo "could not find an ISO on $mirror"; exit 1; }
    iso=cachyos-desktop-linux-$ver.iso
    curl -fsSL -o "$iso.sha256" "$mirror/$ver/$iso.sha256"
    if ! sha256sum -c --status "$iso.sha256"; then
      echo "downloading $iso"
      curl -fL -C - -o "$iso" "$mirror/$ver/$iso"  # resumes an interrupted download
      sha256sum -c --status "$iso.sha256" || { rm -f "$iso"; echo "$iso failed its checksum; run again"; exit 1; }
    fi
    qemu-img create -f qcow2 base.qcow2 40G
    cp /usr/share/edk2/x64/OVMF_VARS.4m.fd base-vars.fd
    disk=base.qcow2 vars=base-vars.fd cdrom="-cdrom $iso -boot d"
    ;;
  base) disk=base.qcow2 vars=base-vars.fd ;;
  run)
    [ -f base.qcow2 ] || { echo "no base.qcow2 yet; run: $0 install"; exit 1; }
    # overlay: writes go to test.qcow2, base.qcow2 stays a clean install
    qemu-img create -q -f qcow2 -b base.qcow2 -F qcow2 test.qcow2
    cp base-vars.fd test-vars.fd
    disk=test.qcow2 vars=test-vars.fd
    ;;
  *) sed -n '2,8p' "$repo/test/vm.sh"; exit 1 ;;
esac

# shellcheck disable=SC2086
exec qemu-system-x86_64 -enable-kvm -machine q35 -cpu host -smp 4 -m 8G \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive if=pflash,format=raw,file="$vars" \
  -drive file="$disk",if=virtio \
  -device virtio-vga-gl -display gtk,gl=on \
  -nic user,model=virtio-net-pci \
  -virtfs local,path="$repo",mount_tag=dotfiles,security_model=none,readonly=on \
  $cdrom
