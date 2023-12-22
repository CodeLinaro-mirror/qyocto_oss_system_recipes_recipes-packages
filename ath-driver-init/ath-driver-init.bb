DESCRIPTION = "Service to setup affinity for wifi drivers"
SECTION = "ath12k-affinity"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}/files:"

inherit systemd

SRC_URI = " \
        file://ath-driver-init.service \
        file://ath-driver-init.sh"

S = "${WORKDIR}/ath12k-driver-init"

do_install() {
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/ath-driver-init.sh ${D}${bindir}
        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/ath-driver-init.service  ${D}${systemd_unitdir}/system
}

FILES:${PN} += " ${bindir}/*"
BBCLASSEXTEND += "native"
SYSTEMD_SERVICE:${PN} += "ath-driver-init.service"

