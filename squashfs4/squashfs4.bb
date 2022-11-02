DESCRIPTION = "squashfs tools"
LICENSE = "GPLv2"
PKG_VERSION = "4.2"
LIC_FILES_CHKSUM = "file://COPYING;md5=0636e73ff0215e8d672dc4c32c317bb3"

SRC_URI = "https://codelinaro.jfrog.io/artifactory/codelinaro-qsdk/squashfs${PKG_VERSION}.tar.gz \
	   file://100-portability.patch \
	   file://110-allow_static_liblzma.patch \
	   file://150-freebsd_fixes.patch \
	   file://160-expose_lzma_xz_options.patch \
	   file://170-add_support_for_LZMA_MAGIC_to_unsqashfs.patch \
	   file://171-fix_gcc7_build.patch \
	"

SRC_URI[sha256sum] = "d9e0195aa922dbb665ed322b9aaa96e04a476ee650f39bbeadb0d00b24022e96"
SRC_URI[md5sum] = "1b7a781fb4cf8938842279bd3e8ee852"

S = "${WORKDIR}/squashfs${PKG_VERSION}/"

DEPENDS =" zlib xz "
DEPENDS +="squashfs4-native"
LDFLAGS_class-native = "-L${STAGING_LIBDIR_NATIVE}"

do_compile() {
	make -C ${S}/squashfs-tools CROSS_COMPILE=${TARGET_PREFIX} XZ_SUPPORT=1 LZMA_XZ_SUPPORT=1 XATTR_SUPPORT=  mksquashfs unsquashfs
}

do_install() {
	install -d  ${D}/usr/sbin
	install -m 755 ${S}squashfs-tools/mksquashfs ${D}/usr/sbin/mksquashfs4
	install -m 755 ${S}squashfs-tools/unsquashfs ${D}/usr/sbin/unsquashfs4
}
do_install_class-native() {
	mkdir -p ${DEPLOY_DIR_IMAGE}
	install -m 755 ${S}squashfs-tools/mksquashfs ${DEPLOY_DIR_IMAGE}/mksquashfs4

}
BBCLASSEXTEND = "native nativesdk"
INSANE_SKIP_${PN} = "ldflags"
