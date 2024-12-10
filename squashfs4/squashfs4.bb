DESCRIPTION = "squashfs tools"
LICENSE = "GPLv2"
PKG_VERSION = "4.6.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = "https://codelinaro.jfrog.io/artifactory/codelinaro-qsdk/squashfs4-${PKG_VERSION}.tar.xz \
	   file://001-xz_wrapper-support-multiple-lzma-configuration-optio.patch \
	   file://002-xz_wrapper-make-new-OpenWrt-extended-options-non-def.patch \
"

SRC_URI[sha256sum] = "fc625af657ca284d69fbc32e3bb572d0afd566cf816b7c1c1b66dda0a0c2760a"
SRC_URI[md5sum] = "f1db65146a33a810a7f3b09ada7acd6e"

S = "${WORKDIR}/squashfs4-${PKG_VERSION}/"

DEPENDS =" zlib xz "
DEPENDS +="squashfs4-native"
LDFLAGS:class-native = "-L${STAGING_LIBDIR_NATIVE}"

do_compile() {
	make -C ${S}/squashfs-tools CROSS_COMPILE=${TARGET_PREFIX} XZ_SUPPORT=1 LZMA_XZ_SUPPORT=1 LDFLAGS+=-static XZ_EXTENDED_OPTIONS=1 mksquashfs unsquashfs
}

do_install() {
	install -d  ${D}/usr/sbin
	install -m 755 ${S}squashfs-tools/mksquashfs ${D}/usr/sbin/mksquashfs4
	install -m 755 ${S}squashfs-tools/unsquashfs ${D}/usr/sbin/unsquashfs4
}
do_install:class-native() {
	mkdir -p ${DEPLOY_DIR_IMAGE}
	install -m 755 ${S}squashfs-tools/mksquashfs ${DEPLOY_DIR_IMAGE}/mksquashfs4
	install -m 755 ${S}squashfs-tools/unsquashfs ${DEPLOY_DIR_IMAGE}/unsquashfs4

}
BBCLASSEXTEND = "native nativesdk"
INSANE_SKIP:${PN} = "ldflags"
