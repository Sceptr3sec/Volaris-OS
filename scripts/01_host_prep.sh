#!/usr/bin/env bash
set -euo pipefail

echo "=== Volaris OS — Host Preparation (T1.1) ==="

# Update package lists and upgrade existing packages
sudo apt update && sudo apt upgrade -y

# Install LFS-required host dependencies
sudo apt install -y \
  build-essential \
  bison \
  gawk \
  texinfo \
  wget \
  xz-utils \
  m4 \
  rsync \
  git \
  python3 \
  gettext

echo "=== Verifying critical tool versions ==="
echo "bash:    $(bash --version | head -n1)"
echo "gcc:     $(gcc --version | head -n1)"
echo "make:    $(make --version | head -n1)"
echo "python3: $(python3 --version)"
echo "bison:   $(bison --version | head -n1)"

echo ""
echo "Host preparation complete."
echo "Cross-check versions above against the LFS book's host requirements table"
echo "before proceeding to 02_build_lfs.sh."