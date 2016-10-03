DESCRIPTION = "uci"
SECTION = "uci"
LICENSE = "LGPLv2.1"
PR = "r0"
LIC_FILES_CHKSUM = "file://uci.h;endline=13;md5=0ee862ed12171ee619c8c2eb7eff77f2"

DEPENDS = "json-c libubox lua5.1"

inherit cmake pkgconfig

SRC_URI = "http://dev.gateworks.com/sources/uci-2015-08-27.1.tar.gz \
           file://config_files"

SRC_URI[md5sum] = "b5f71c32ecc69f4ad09984ed8fadd702"

S = "${WORKDIR}/uci-2015-08-27.1"

EXTRA_OECMAKE += '-DLIBARCH=${baselib} \
            -DLUAPATH=${libdir}/lua \
            -DCMAKE_MODULE_LINKER_FLAGS:STRING="-L${STAGING_LIBDIR}" \
            -DCMAKE_EXE_LINKER_FLAGS:STRING="-L${STAGING_LIBDIR}" \
            -DCMAKE_SHARED_LINKER_FLAGS:STRING="-L${STAGING_LIBDIR}" \
            -DCMAKE_FIND_ROOT_PATH=${STAGING_DIR_HOST}'

do_install_append() {
    mkdir -p ${D}/etc/uci-defaults
    mv ${D}/usr/bin ${D}/sbin

    cp -a ${WORKDIR}/config_files/* ${D}/
	install -d ${D}${libdir}
	install -m 0755 ${WORKDIR}/config_files/lib/ipq806x.sh ${D}/lib/
	install -d ${D}/etc/uci-defaults/
	install -m 0755 ${WORKDIR}/config_files/etc/uci-defaults/network ${D}/etc/uci-defaults/
	install -d ${D}/etc/init.d/
	install -m 0755 ${WORKDIR}/config_files/etc/init.d/network ${D}/etc/init.d/network
}

FILES_${PN} += "${libdir}/* ${baselib}/* ${sysconfdir}/*"

FILES_${PN}-dbg += "${libdir}/lua/.debug"

FILES_${PN}-dev = "/usr/include/*"

INSANE_SKIP_${PN} = "dev-so"

BBCLASSEXTEND += "native"
