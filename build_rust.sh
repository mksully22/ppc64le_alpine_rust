#
# Usage:
# $ sudo docker run --name alpine_rustbuild  -it -v /rust-alpine-ppc64le:/mnt alpine:3.7
# $ sudo docker exec -it alpine_rustbuild  /bin/bash
# $ sudo docker ps
# # inside the docker container
# modify /etc/apk/repositories to point to edge
# apk update
# apk upgrade
# Copy the contents of this directory to build_rust.sh, patches to /root/test/.
# as root, execute /root/test/build_rust.sh
# TODOS:

set -ex

user=rustbuild
sourcedir=/root/test

as_user() {
    su -c 'bash -c "'"${@}"'"' $user
}

mk_user() {
    adduser -D $user
}

fetch_rust() {
    cd /home/$user; cp -r $sourcedir /home/$user/.; chown -R rustbuild:rustbuild /home/$user/test;
    as_user "
    rm -rf ~/rust; tar -xzf ~/test/rustc-1.24.1-src.tar.gz; mv rustc-1.24.1-src rust;
"
}

install_deps() {
        apk add alpine-sdk gcc llvm-libunwind-dev cmake file libffi-dev llvm4-dev llvm4-test-utils python2 tar zlib-dev gcc llvm-libunwind-dev musl-dev util-linux bash
        apk add --allow-untrusted $sourcedir/rust-stdlib-1.24.1-r0.apk $sourcedir/rust-1.24.1-r0.apk $sourcedir/cargo-0.25.0-r1.apk
}

apply_patches() {
    # TODO upstream these patches to rust-lang/llvm
    as_user "
cd ~/rust
rm -Rf src/llvm/
patch -p1 -b < ~/test/minimize-rpath.patch
patch -p1 -b < ~/test/install-template-shebang.patch
patch -p1 -b < ~/test/static-pie.patch
patch -p1 -b < ~/test/need-rpath.patch
patch -p1 -b < ~/test/musl-fix-static-linking.patch
patch -p1 -b < ~/test/musl-fix-linux_musl_base.patch
patch -p1 -b < ~/test/llvm-with-ffi.patch
patch -p1 -b < ~/test/alpine-target.patch
patch -p1 -b < ~/test/alpine-move-py-scripts-to-share.patch
patch -p1 -b < ~/test/alpine-change-rpath-to-rustlib.patch
patch -p1 -b < ~/test/s7_ppc64le_target.patch
patch -p1 -b < ~/test/s7_liblibc_modrs.patch
patch -p1 -b < ~/test/s7_liblibc_b64x86_64.patch
patch -p1 -b < ~/test/s7_liblibc_b64powerpc64.patch
patch -p1 -b < ~/test/s7_liblibc_b64modrs.patch
patch -p1 -b < ~/test/s7_liblibc_b32modrs.patch
patch -p1 -b < ~/test/s7_cargo_libc_modrs.patch
patch -p1 -b < ~/test/s7_cargo_libc_b64x86_64.patch
patch -p1 -b < ~/test/s7_cargo_libc_b64powerpc64le.patch
patch -p1 -b < ~/test/s7_cargo_libc_b64modrs.patch
patch -p1 -b < ~/test/s7_cargo_libc_b32modrs.patch
patch -p1 -b < ~/test/s7_cargo_libc_checksum.patch
"
}


mk_rustc() {
    dir=$(pwd)
    as_user "
cd ~/rust
./configure \
                --build="powerpc64le-alpine-linux-musl" \
                --host="powerpc64le-alpine-linux-musl" \
                --target="powerpc64le-alpine-linux-musl" \
                --prefix="/usr" \
                --release-channel="stable" \
                --enable-local-rust \
                --local-rust-root="/usr" \
                --llvm-root="/usr/lib/llvm4" \
                --musl-root="/usr" \
                --disable-docs \
                --enable-llvm-link-shared \
                --enable-option-checking \
                --enable-locked-deps \
                --enable-vendor \
                --disable-jemalloc

                unset MAKEFLAGS
                date > build_dist.log
                RUST_BACKTRACE=1 RUSTC_CRT_STATIC="false" taskset 0x1 ./x.py dist -j1 -v >> build_dist.log 2>&1
                date >> build_dist.log
"
}


main() {
   mk_user
   install_deps
   fetch_rust
   apply_patches
   mk_rustc
}

main
