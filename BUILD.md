# Build Instructions

## Host Requirements

- WSL2 (Ubuntu) or native Linux, x86-64
- ~4 GB free disk space minimum for LFS sources + build
- Internet access during build (for source package downloads)

## Steps

1. `./scripts/01_prepare_host.sh` — installs required host packages
2. `./scripts/02_build_lfs.sh` — builds the LFS toolchain and base system *(not yet written)*
3. ...

## Notes

- Build must run inside WSL2's native filesystem (e.g. `~/build/volaris-os`),
  **not** under `/mnt/c/...` — permissions and symlinks break under the
  Windows-mounted filesystem.