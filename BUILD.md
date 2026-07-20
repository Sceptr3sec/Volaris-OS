# Build Instructions

## Host Requirements

- WSL2 (Ubuntu 24.04) or native Linux, x86-64
- LFS Book: 13.0-systemd
- Several GB free disk space for LFS sources + build
- Internet access during build (for source package downloads)

## Environment

Build must run inside WSL2's native filesystem (e.g. `~/build/volaris-os`),
**not** under `/mnt/c/...` — permissions and symlinks break under the
Windows-mounted filesystem.

A clean build environment is maintained via `~/lfs-env.sh` (sourced manually
each session) rather than a dedicated `lfs` user, as a documented deviation
from the LFS book's Chapter 4.3 recommendation. This still provides clean
PATH/umask/locale isolation from the host without the ownership overhead of
a separate Unix user.

## Steps Completed So Far

1. Host packages installed (T1.1)
2. LFS directory layout created: `lfs-root/{etc,var,usr/{bin,lib,sbin},lib64}`,
   with `bin`/`lib`/`sbin` symlinked into `usr/` (T1.2)
3. Cross-toolchain built and verified (T1.3):
   - Binutils-2.46.0 (Pass 1)
   - GCC-15.2.0 (Pass 1)
   - Linux-6.18.10 API Headers
   - Glibc-2.43 (with FHS patch)
   - Libstdc++ (from GCC-15.2.0)
   - All sanity checks (start files, header search paths, linker search
     paths, libc/dynamic-linker resolution) passed against `$LFS`, confirmed
     isolated from host paths.

## Next Steps

4. Chapter 6 — Temporary tools (T1.4)
5. Chroot into LFS environment, build final system (T1.5)

## Notes

- Source tarballs and the entire build tree (`lfs-root/`) are intentionally
  excluded from version control (see `.gitignore`) — regeneratable from
  these scripts/instructions, and far too large for a git repo.

## Known issue: GCC Pass 1 internal limits.h

If a Chapter 6 package fails to build with an error like
`#error "Assumed value of MB_LEN_MAX wrong"` in a glibc header, it means
the GCC Pass 1 internal `limits.h` was left as its partial, pre-glibc
placeholder version. Fix by regenerating it from GCC's own source fragments:

    cd $LFS/sources/gcc-15.2.0
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
      `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

This step is normally done immediately after GCC Pass 1's `make install`
(before Glibc), per LFS 13.0-systemd Section 5.3. It was applied
retroactively here after M4 exposed the issue in Chapter 6.

## Chapter 6 — Temporary Tools (T1.4)

All temporary tools built via `scripts/02_build_temp_tools.sh`:
M4, Ncurses, Bash, Coreutils, Diffutils, File, Findutils, Gawk, Grep, Gzip,
Make, Patch, Sed, Tar, Xz, Binutils (Pass 2), GCC (Pass 2).

Script is idempotent — safe to re-run; completed packages are tracked via
marker files in `logs/.done/` and skipped automatically.

## Custom Initramfs (RAM-Resident Boot)

Located at `initramfs/init`. Built with a statically-linked BusyBox
(1.36.1, CONFIG_TC disabled due to a GCC-15 incompatibility, CONFIG_STATIC=y).

Mechanism: mounts /proc, /sys, /dev; creates a tmpfs at /mnt/runtime
(size=8G, sized for current ~6.5GB base system + headroom); mounts the
base OS partition read-only, copies it into tmpfs, unmounts it immediately;
switch_root's into the tmpfs copy, execing the real /sbin/init (systemd).

Verified live: after boot, `mount | grep sda` returns nothing — the disk
is fully disconnected from the running system, root is confirmed tmpfs.
This is the mechanism backing NFR-01 (no persistent forensic artifacts)
and TC-02 (RAM-only filesystem verification).

Known deviation: base OS is currently ~6.5GB, exceeding the ~4GB target
in Section 1.7 of the planning doc. Trimming (docs, man pages, unused
locales) is a follow-up task before this fully meets NFR-03.

## Custom Initramfs (RAM-Resident Boot)

Located at `initramfs/init`. Built with a statically-linked BusyBox
(1.36.1, CONFIG_TC disabled due to a GCC-15 incompatibility, CONFIG_STATIC=y).

Mechanism: mounts /proc, /sys, /dev; creates a tmpfs at /mnt/runtime
(size=8G, sized for current ~6.5GB base system + headroom); mounts the
base OS partition read-only, copies it into tmpfs, unmounts it immediately;
switch_root's into the tmpfs copy, execing the real /sbin/init (systemd).

Verified live: after boot, `mount | grep sda` returns nothing — the disk
is fully disconnected from the running system, root is confirmed tmpfs.
This is the mechanism backing NFR-01 (no persistent forensic artifacts)
and TC-02 (RAM-only filesystem verification).

Known deviation: base OS is currently ~6.5GB, exceeding the ~4GB target
in Section 1.7 of the planning doc. Trimming (docs, man pages, unused
locales) is a follow-up task before this fully meets NFR-03.

## Bootable ISO (Day 4 checkpoint — complete)

`volaris-os.iso` (~6.4GB) built via `grub-mkrescue`, containing:
- Custom kernel (linux-6.18.10) + GRUB
- Custom initramfs (BusyBox-based, RAM-resident switch_root mechanism)
- Full base OS system (`volaris-base/`, ~6.4GB) embedded directly on the ISO

Init script searches multiple device candidates (/dev/sr0 for ISO boot,
/dev/sda1 for raw disk image testing) and detects whether the base OS is
at a `volaris-base` subdirectory (ISO layout) or the mount root directly
(raw disk image layout) — one script correctly handles both.

Verified: boots from ISO in QEMU, reaches login, root confirmed as tmpfs,
boot media confirmed unmounted post-boot — matches NFR-01/TC-02.

Build command (must run as root — iso-root/volaris-base contains
root-owned files with restrictive permissions unprivileged xorriso can't read):
    sudo grub-mkrescue -o volaris-os.iso iso-root

## Firewall / Hardening (Day 5 — complete)

nftables 1.1.1 built (not part of base LFS — required libmnl 1.0.5,
libnftnl 1.2.9, libedit, jansson as additional dependencies).

Two real bugs found and fixed during verification:
1. Kernel never had CONFIG_NF_TABLES enabled — base LFS kernel config
   doesn't include netfilter/nftables support. Rebuilt kernel with
   NF_TABLES, NF_CONNTRACK, and related options as built-in (=y), not
   modules — avoids a module-load timing race at early boot.
2. GMP (a build dependency of nftables) auto-detects and compiles for
   the exact host CPU by default, causing "illegal instruction" crashes
   when run on a different/more conservative CPU (e.g., QEMU's default
   emulated CPU vs. the WSL2 host's real CPU used during chroot builds).
   Fixed by rebuilding GMP with --host=none-linux-gnu to force portable
   code generation. Rebuilt nftables afterward to link against the fix.

Default-deny policy (see nftables.conf) verified via nmap from host:
999/1000 scanned ports report filtered (no-response). The one open port
(53/tcp) is QEMU's own NAT gateway DNS, not a Volaris service — confirmed
via `ss -tlnp` showing systemd-resolved bound only to 127.0.0.53/54
(loopback), never externally reachable.

Service loads automatically at boot via nftables.service
(DefaultDependencies=no, After=sysinit.target, Before=basic.target,
TimeoutStartSec=15) — deliberately ordered to never block console/login
availability even if the service itself fails.

## Cybersecurity Toolkit (Day 6 — complete)

Three tools built and verified functional in the actual booted ISO
(not just chroot, given the CPU-portability lessons from nftables):

- **htop 3.4.1** — process/resource monitoring
- **tcpdump 4.99.5** (+ libpcap 1.10.5) — network traffic capture
- **nmap 7.95** — network scanning/enumeration (built with bundled Lua/NSE,
  libssh2, linked against system OpenSSL/zlib/pcre2/libpcap)

All three built proactively with `-march=x86-64 -mtune=generic` to avoid
a repeat of the GMP CPU-auto-detection crash found during Day 5 — no
illegal-instruction issues observed in the actual QEMU-emulated boot.

## Persistence Verification (Day 6 — TC-02/TC-04 evidence)

- TC-02 confirmed: post-boot, `mount | grep sda` / `mount | grep sr0`
  return nothing — boot media is fully disconnected after RAM hydration.
- TC-04 confirmed: created `/root/sentinel.txt` with known content,
  rebooted from the same ISO, file confirmed absent
  (`cat: No such file or directory`) — no session data survives a reboot.

## Final Image Size

Base system: ~4.3GB (down from an initial ~6.5GB — a stray Chapter 7
backup archive, lfs-temp-tools-13.0-systemd.tar.xz, had been mistakenly
left at the filesystem root and was being copied into every ISO rebuild;
removed once discovered while investigating GitHub's 2GB release asset
limit). Final size is now consistent with the ~4GB target in Section 1.7
of the project planning document.

Compressed ISO (xz -6): ~944MB. Uncompressed: ~6.5GB total ISO
(includes the ~4.3GB base system plus GRUB/kernel/initramfs).

Released as a GitHub Release asset (v1.0-final), per Section 6.8 of the
project plan, rather than committed to the repository directly.
