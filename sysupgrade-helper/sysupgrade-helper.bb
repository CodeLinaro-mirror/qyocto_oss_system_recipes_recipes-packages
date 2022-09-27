DESCRIPTION = "Sysupgrade-helper script"

LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=801f80980d171dd6425610833a22dbe6"


FILESPATH =+ "${TOPDIR}/../boot/:"

COMPATIBLE_MACHINE = "(ipq40xx|ipq807x|ipq95xx)"

SRC_URI = "file://u-boot-2016 \
           file://config"

S = "${WORKDIR}/u-boot-2016"

EXTRA_OEMAKE = 'CROSS_COMPILE=${TARGET_PREFIX} CC="${TARGET_PREFIX}gcc ${TOOLCHAIN_OPTIONS}" STRIP=true V=1'
EXTRA_OEMAKE += 'TARGETCC="${CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS} -Wno-error "'
PARALLEL_MAKE = "-j 1"


inherit uboot-config systemd


do_configure () {
        cp ${S}/../config ${S}/.config
        mkdir -p ${S}/include/generated
        touch ${S}/include/generated/autoconf.h
        sed -i 's/HOSTCC       = cc/HOSTCC       = gcc/g' ${S}/Makefile
}

do_compile () {
        oe_runmake tools-only
}

do_install () {
        install -d ${D}${base_sbindir}
        install -d ${D}${sysconfdir}
        install -m 755 ${S}/tools/dumpimage ${D}${base_sbindir}/dumpimage
}

