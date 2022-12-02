DESCRIPTION = "Service to load ath12k driver while bootup"
SECTION = "ath12k-load"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}/files:"

inherit systemd

SRC_URI = "file://ath-autoload.service"

S = "${WORKDIR}/ath12k-load"

do_install() {
	install -d ${D}${systemd_unitdir}/system
	install -m 0644 ${WORKDIR}/ath-autoload.service  ${D}${systemd_unitdir}/system
}

FILES_${PN} += " ${bindir}/*"
BBCLASSEXTEND += "native"
SYSTEMD_SERVICE_${PN} += "ath-autoload.service"
