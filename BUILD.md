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
