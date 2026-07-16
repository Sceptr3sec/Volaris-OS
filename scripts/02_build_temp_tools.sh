#!/usr/bin/env bash
# Volaris OS — LFS 13.0-systemd, Chapter 6 (Temporary Tools), remaining packages
# File -> Findutils -> Gawk -> Grep -> Gzip -> Make -> Patch -> Sed -> Tar -> Xz
#      -> Binutils Pass 2 -> GCC Pass 2
#
# Idempotent: safe to re-run any time, including after a failure.
# Already-completed packages are skipped automatically via marker files
# in logs/.done/. Each package's source dir is wiped before re-extracting,
# so leftover build/ directories from a previous attempt never collide.

set -euo pipefail

LOGDIR=~/build/volaris-os/logs
DONEDIR="$LOGDIR/.done"
mkdir -p "$LOGDIR" "$DONEDIR"

log() { echo "=== $1 ==="; }

already_done() { [ -f "$DONEDIR/$1" ]; }
mark_done()    { touch "$DONEDIR/$1"; }

run_pkg() {
  local name="$1"
  local func="$2"
  if already_done "$name"; then
    log "$name — already done, skipping"
    return 0
  fi
  log "$name"
  "$func" 2>&1 | tee "$LOGDIR/$name.log"
  mark_done "$name"
}

build_file() {
  cd "$LFS/sources"
  rm -rf file-5.46
  tar xf file-5.46.tar.gz
  cd file-5.46

  mkdir build
  pushd build
    ../configure --disable-bzlib --disable-libseccomp --disable-xzlib --disable-zlib
    make
  popd

  ./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
  make FILE_COMPILE=$(pwd)/build/src/file
  make DESTDIR=$LFS install
  rm -v $LFS/usr/lib/libmagic.la
}

build_findutils() {
  cd "$LFS/sources"
  rm -rf findutils-4.10.0
  tar xf findutils-4.10.0.tar.xz
  cd findutils-4.10.0

  ./configure --prefix=/usr \
              --localstatedir=/var/lib/locate \
              --host=$LFS_TGT \
              --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
}

build_gawk() {
  cd "$LFS/sources"
  rm -rf gawk-5.3.2
  tar xf gawk-5.3.2.tar.xz
  cd gawk-5.3.2

  sed -i 's/extras//' Makefile.in

  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
}

build_grep() {
  cd "$LFS/sources"
  rm -rf grep-3.12
  tar xf grep-3.12.tar.xz
  cd grep-3.12

  ./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
  make
  make DESTDIR=$LFS install
}

build_gzip() {
  cd "$LFS/sources"
  rm -rf gzip-1.14
  tar xf gzip-1.14.tar.xz
  cd gzip-1.14

  ./configure --prefix=/usr --host=$LFS_TGT
  make
  make DESTDIR=$LFS install
}

build_make() {
  cd "$LFS/sources"
  rm -rf make-4.4.1
  tar xf make-4.4.1.tar.gz
  cd make-4.4.1

  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
}

build_patch() {
  cd "$LFS/sources"
  rm -rf patch-2.8
  tar xf patch-2.8.tar.xz
  cd patch-2.8

  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
}

build_sed() {
  cd "$LFS/sources"
  rm -rf sed-4.9
  tar xf sed-4.9.tar.xz
  cd sed-4.9

  ./configure --prefix=/usr --host=$LFS_TGT --build=$(./build-aux/config.guess)
  make
  make DESTDIR=$LFS install
}

build_tar() {
  cd "$LFS/sources"
  rm -rf tar-1.35
  tar xf tar-1.35.tar.xz
  cd tar-1.35

  ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess)
  make
  make DESTDIR=$LFS install
}

build_xz() {
  cd "$LFS/sources"
  rm -rf xz-5.8.2
  tar xf xz-5.8.2.tar.xz
  cd xz-5.8.2

  ./configure --prefix=/usr \
              --host=$LFS_TGT \
              --build=$(build-aux/config.guess) \
              --disable-static \
              --docdir=/usr/share/doc/xz-5.8.2
  make
  make DESTDIR=$LFS install
  rm -v $LFS/usr/lib/liblzma.la
}

build_binutils_pass2() {
  cd "$LFS/sources"
  rm -rf binutils-2.46.0
  tar xf binutils-2.46.0.tar.xz
  cd binutils-2.46.0

  sed '6031s/$add_dir//' -i ltmain.sh

  mkdir -v build
  cd build

  ../configure \
      --prefix=/usr \
      --build=$(../config.guess) \
      --host=$LFS_TGT \
      --disable-nls \
      --enable-shared \
      --enable-gprofng=no \
      --disable-werror \
      --enable-64-bit-bfd \
      --enable-new-dtags \
      --enable-default-hash-style=gnu

  make
  make DESTDIR=$LFS install

  rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
}

build_gcc_pass2() {
  cd "$LFS/sources"
  rm -rf gcc-15.2.0
  tar xf gcc-15.2.0.tar.xz
  cd gcc-15.2.0

  tar -xf ../mpfr-4.2.2.tar.xz && mv -v mpfr-4.2.2 mpfr
  tar -xf ../gmp-6.3.0.tar.xz && mv -v gmp-6.3.0 gmp
  tar -xf ../mpc-1.3.1.tar.gz && mv -v mpc-1.3.1 mpc

  case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    ;;
  esac

  sed '/thread_header =/s/@.*@/gthr-posix.h/' \
      -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

  mkdir -v build
  cd build

  ../configure \
      --build=$(../config.guess) \
      --host=$LFS_TGT \
      --target=$LFS_TGT \
      --prefix=/usr \
      --with-build-sysroot=$LFS \
      --enable-default-pie \
      --enable-default-ssp \
      --disable-nls \
      --disable-multilib \
      --disable-libatomic \
      --disable-libgomp \
      --disable-libquadmath \
      --disable-libsanitizer \
      --disable-libssp \
      --disable-libvtv \
      --enable-languages=c,c++ \
      LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc

  make
  make DESTDIR=$LFS install

  ln -sv gcc $LFS/usr/bin/cc
}

# --- Run in order. Re-running this script is always safe — completed
#     packages are skipped automatically via marker files in logs/.done/ ---
run_pkg "file"           build_file
run_pkg "findutils"      build_findutils
run_pkg "gawk"           build_gawk
run_pkg "grep"           build_grep
run_pkg "gzip"           build_gzip
run_pkg "make"           build_make
run_pkg "patch"          build_patch
run_pkg "sed"            build_sed
run_pkg "tar"            build_tar
run_pkg "xz"             build_xz
run_pkg "binutils-pass2" build_binutils_pass2
run_pkg "gcc-pass2"      build_gcc_pass2

echo "=== Chapter 6 (Temporary Tools) complete ==="