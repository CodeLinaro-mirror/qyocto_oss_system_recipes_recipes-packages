LICENSE = "GPLv2+"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://config_files"

do_configure:append() {
	touch ${S}/configs/${UBOOT_MACHINE}
}

do_install:append() {
	rm ${D}${sysconfdir}/fw_env.config
	install -d ${D}/lib/
	install -m 0755 ${WORKDIR}/config_files/uboot-envtools.sh ${D}/lib/
	install -d ${D}/etc/uci-defaults/
	install -m 0755 ${WORKDIR}/config_files/ipq806x ${D}/etc/uci-defaults/30_uboot-envtools
}

FILES:${PN} += "${libdir}/* ${baselib}/* ${sysconfdir}/*"
