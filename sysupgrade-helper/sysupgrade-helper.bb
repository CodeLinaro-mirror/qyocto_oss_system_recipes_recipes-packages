DESCRIPTION = "Sysupgrade-helper script"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=801f80980d171dd6425610833a22dbe6"


FILESPATH =+ "${TOPDIR}/../boot/:"

COMPATIBLE_MACHINE = "(ipq40xx|ipq807x|ipq95xx|ipq53xx|ipq95xx_64|ipq53xx_64|ipq54xx_64)"

SRC_URI = "file://u-boot \
           file://config"

S = "${WORKDIR}/u-boot"

DEPENDS += "openssl"

IMG_FLAG:ipq54xx_64 = "-DIPQ54XX"
SHA_FLAG = "-DUSE_SHA256"
SHA_FLAG:ipq95xx_64 = "-DUSE_SHA384"
SHA_FLAG:ipq54xx_64 = "-DUSE_SHA384"

EXTRA_OEMAKE = 'CROSS_COMPILE=${TARGET_PREFIX} CC="${TARGET_PREFIX}gcc ${TOOLCHAIN_OPTIONS}" STRIP=true V=1'
EXTRA_OEMAKE += 'TARGETCC="${CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS} -Wno-error "'
PARALLEL_MAKE = "-j 1"

TARGET_CC_ARCH += "${LDFLAGS}"

inherit uboot-config systemd

do_configure () {
        mkdir -p ${S}/include/config
        echo "CONFIG_FIT=y" >> ${S}/include/config/auto.conf
        echo "CONFIG_FIT_PRINT=y" >> ${S}/include/config/auto.conf
        echo "CONFIG_TOOLS_FIT=y" >> ${S}/include/config/auto.conf
        echo "CONFIG_TOOLS_FIT_PRINT=y" >> ${S}/include/config/auto.conf
        echo "CONFIG_SYSUPGRADE_HELPER=y" >> ${S}/include/config/auto.conf
        touch ${S}/include/config/auto.conf
        mkdir -p ${S}/include/generated
        echo "#define CONFIG_FIT_PRINT 1" >> ${S}/include/generated/autoconf.h
        echo "#define CONFIG_FIT 1" >> ${S}/include/generated/autoconf.h
        echo "#define CONFIG_TOOLS_FIT 1" >> ${S}/include/generated/autoconf.h
        echo "#define CONFIG_TOOLS_FIT_PRINT 1" >> ${S}/include/generated/autoconf.h
        echo "#define CONFIG_SYSUPGRADE_HELPER 1" >> ${S}/include/generated/autoconf.h
        touch ${S}/include/generated/autoconf.h
        sed -i 's/HOSTCC       = cc/HOSTCC       = gcc/g' ${S}/Makefile
}


do_compile () {
        oe_runmake -C ${S} HOSTCFLAGS="${SHA_FLAG} ${IMG_FLAG} -fPIC" HOSTLDLIBS_mkimage="-static -lpthread -lcrypto -lssl" CROSS_BUILD_TOOLS=y no-dot-config-targets=tools-only tools-only
}

do_install () {
        install -d ${D}${base_sbindir}
        install -d ${D}${sysconfdir}
        install -m 755 ${S}/tools/dumpimage ${D}${base_sbindir}/dumpimage
        install -m 755 ${S}/tools/mkimage ${D}${base_sbindir}/mkimage
}
