DESCRIPTION = "ipq-board scripts to detect IPQ board"
SECTION = "ipq-board"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

PR = "r0"

inherit systemd

SRC_URI = "file://ipq-board "

S = "${WORKDIR}/ipq-board"

do_install_append() {
	install -d ${D}/lib
	install -d ${D}${bindir}

	install -m 0755 ${WORKDIR}/ipq-board/lib/ipq.sh ${D}/lib/ipq.sh
	install -m 0755 ${WORKDIR}/ipq-board/usr/bin/ipq-board ${D}${bindir}

	install -d ${D}${systemd_unitdir}/system
	install -m 0644 ${WORKDIR}/ipq-board/ipq-board.service  ${D}${systemd_unitdir}/system
}

FILES_${PN} += "${libdir}/* ${baselib}/* ${sysconfdir}/* ${bindir}/*"
SYSTEMD_SERVICE_${PN} += "ipq-board.service"
