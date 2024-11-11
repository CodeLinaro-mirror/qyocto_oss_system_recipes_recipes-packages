SUMMARY = "Implementation of a fully functional filesystem in a userspace program"
DESCRIPTION = "FUSE (Filesystem in Userspace) is a simple interface for userspace \
               programs to export a virtual filesystem to the Linux kernel. FUSE \
               also aims to provide a secure method for non privileged users to \
               create and mount their own filesystem implementations. \
              "
HOMEPAGE = "http://fuse.sf.net"
SECTION = "libs"
LICENSE = "GPLv2 & LGPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263 \
                    file://COPYING.LIB;md5=4fbd65380cdd255951079008b364516c"

SRC_URI = "https://github.com/libfuse/libfuse/archive/refs/tags/fuse_2_9_3.tar.gz \
           file://gold-unversioned-symbol.patch \
           file://aarch64.patch \
           file://001-fix_exec_environment_for_mount_and_umount.patch \
           file://fuse2-0007-util-ulockmgr_server.c-conditionally-define-closefro.patch \
"
SRC_URI[md5sum] = "bec8bcea0637425d115f7c543ebfc750"
SRC_URI[sha256sum] = "67cc2a7f53fb9426c0328a588004886981cddcce53024265a8fb8494476d1329"

S = "${WORKDIR}/libfuse-fuse_2_9_3"

inherit autotools pkgconfig

DEPENDS = "gettext-native"

PACKAGES =+ "fuse-utils-dbg fuse-utils libulockmgr libulockmgr-dev libulockmgr-dbg"

RRECOMMENDS:${PN} = "kernel-module-fuse"

FILES:${PN} += "${libdir}/libfuse.so.*"
FILES:${PN}-dev += "${libdir}/libfuse*.la"

FILES:libulockmgr = "${libdir}/libulockmgr.so.*"
FILES:libulockmgr-dev += "${libdir}/libulock*.la"
FILES:libulockmgr-dbg += "${libdir}/.debug/libulock*"

# Forbid auto-renaming to libfuse-utils
FILES:fuse-utils = "${bindir} ${base_sbindir}"
FILES:fuse-utils-dbg = "${bindir}/.debug ${base_sbindir}/.debug"
DEBIAN_NOAUTONAME_fuse-utils = "1"
DEBIAN_NOAUTONAME_fuse-utils-dbg = "1"

do_configure:prepend() {
    cp -af ${STAGING_DIR_NATIVE}/usr/share/gettext/config.rpath ${S}
}

do_install:append() {
    rm -rf ${D}${base_prefix}/dev
}
