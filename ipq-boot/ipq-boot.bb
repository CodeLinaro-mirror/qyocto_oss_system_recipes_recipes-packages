DESCRIPTION = "ipq-boot scripts to boot and detect IPQ board"
SECTION = "ipq-boot"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

PR = "r0"

inherit systemd

SRC_URI = "file://ipq-boot \
	file://reset_to_factory_settings.sh "

S = "${WORKDIR}/ipq-boot"

do_install:append() {
	install -d ${D}/lib
	install -d ${D}/sbin
	install -d ${D}${bindir}

	install -m 0755 ${WORKDIR}/ipq-boot/lib/ipq.sh ${D}/lib/ipq.sh
	install -m 0755 ${WORKDIR}/ipq-boot/usr/bin/ipq-boot ${D}${bindir}
	install -m 0755 ${WORKDIR}/reset_to_factory_settings.sh ${D}/sbin/reset_to_factory_settings.sh

	install -d ${D}${systemd_unitdir}/system
	install -m 0644 ${WORKDIR}/ipq-boot/ipq-boot.service  ${D}${systemd_unitdir}/system
}

FILES:${PN} += "${libdir}/* ${baselib}/* ${sysconfdir}/* ${bindir}/*"

BBCLASSEXTEND += "native"
SYSTEMD_SERVICE:${PN} += "ipq-boot.service"
