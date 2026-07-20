# Volaris OS

A lightweight, security-focused, RAM-resident operating environment built
from Linux From Scratch, targeting cybersecurity operations.

See `BUILD.md` for build instructions.

## Status

- [x] T1.1 — Host environment prepared
- [x] T1.2 — LFS directory layout created
- [x] T1.3 — Cross-compilation toolchain (binutils, gcc-pass1, glibc, libstdc++)
- [x] T1.4 — Temporary tools (Chapter 6)
- [x] T1.5 — Chroot entered, final system built (Chapters 7-8 complete)
- [x] T1.6 — Kernel configured and built
- [x] T1.7 — GRUB bootloader configured
- [x] T1.8 — Bootable VM image validated (QEMU, persistent-disk boot)
- [x] Bootable ISO produced and verified (Day 4 checkpoint)

## Build

See [BUILD.md](./BUILD.md).

## Test Evidence Captured
- TC-02 (RAM-only filesystem): verified — root is tmpfs, boot media disconnected post-boot
- TC-04 (session cleanup on shutdown): verified — sentinel file test, data does not survive reboot
- TC-05 (firewall default-deny): verified — nmap scan from host shows 999/1000 ports filtered
