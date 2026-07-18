#!/usr/bin/env bash
# Run INSIDE the chroot environment. LFS 13.0-systemd, Chapter 7.7-7.12.
set -euo pipefail

LOGDIR=/root/build-logs
DONEDIR="$LOGDIR/.done"
mkdir -p "$LOGDIR" "$DONEDIR"

log() { echo "=== $1 ==="; }
already_done() { [ -f "$DONEDIR/$1" ]; }
mark_done()    { touch "$DONEDIR/$1"; }

run_pkg() {
  local name="$1"; local func="$2"
  if already_done "$name"; then log "$name — already done, skipping"; return 0; fi
  log "$name"
  "$func" 2>&1 | tee "$LOGDIR/$name.log"
  mark_done "$name"
}

build_gettext() {
  cd /sources; rm -rf gettext-1.0
  tar xf gettext-1.0.tar.xz; cd gettext-1.0
  ./configure --disable-shared
  make
  cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
}

build_bison() {
  cd /sources; rm -rf bison-3.8.2
  tar xf bison-3.8.2.tar.xz; cd bison-3.8.2
  ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
  make
  make install
}

build_perl() {
  cd /sources; rm -rf perl-5.42.0
  tar xf perl-5.42.0.tar.xz; cd perl-5.42.0
  sh Configure -des \
    -D prefix=/usr \
    -D vendorprefix=/usr \
    -D useshrplib \
    -D privlib=/usr/lib/perl5/5.42/core_perl \
    -D archlib=/usr/lib/perl5/5.42/core_perl \
    -D sitelib=/usr/lib/perl5/5.42/site_perl \
    -D sitearch=/usr/lib/perl5/5.42/site_perl \
    -D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
    -D vendorarch=/usr/lib/perl5/5.42/vendor_perl
  make
  make install
}

build_python() {
  cd /sources; rm -rf Python-3.14.3
  tar xf Python-3.14.3.tar.xz; cd Python-3.14.3
  ./configure --prefix=/usr \
              --enable-shared \
              --without-ensurepip \
              --without-static-libpython
  make
  # NOTE: an OpenSSL warning here is expected and harmless — ssl module
  # deps aren't installed yet, comes in Chapter 8. Don't stop for it.
  make install
}

build_texinfo() {
  cd /sources; rm -rf texinfo-7.2
  tar xf texinfo-7.2.tar.xz; cd texinfo-7.2
  ./configure --prefix=/usr
  make
  make install
}

build_util_linux() {
  mkdir -pv /var/lib/hwclock
  cd /sources; rm -rf util-linux-2.41.3
  tar xf util-linux-2.41.3.tar.xz; cd util-linux-2.41.3
  ./configure --libdir=/usr/lib \
              --runstatedir=/run \
              --disable-chfn-chsh \
              --disable-login \
              --disable-nologin \
              --disable-su \
              --disable-setpriv \
              --disable-runuser \
              --disable-pylibmount \
              --disable-static \
              --disable-liblastlog2 \
              --without-python \
              ADJTIME_PATH=/var/lib/hwclock/adjtime \
              --docdir=/usr/share/doc/util-linux-2.41.3
  make
  make install
}

run_pkg "gettext"    build_gettext
run_pkg "bison"      build_bison
run_pkg "perl"       build_perl
run_pkg "python"     build_python
run_pkg "texinfo"    build_texinfo
run_pkg "util-linux" build_util_linux

echo "=== Chapter 7.7-7.12 complete ==="