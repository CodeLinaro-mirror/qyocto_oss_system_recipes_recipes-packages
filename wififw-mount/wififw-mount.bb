DESCRIPTION = "Enable Wi-Fi Firmware Mounting Service and Script into the image"
SECTION = "wififw-mount"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}/files:"

inherit systemd

SRC_URI = " \
    file://wififw-mount.service \
    file://wififw-mount.sh \
"

S = "${WORKDIR}/wififw-mount"

do_install_append() {
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/wififw-mount.sh ${D}${bindir}

        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/wififw-mount.service  ${D}${systemd_unitdir}/system
}

FILES_${PN} += " ${bindir}/*"
BBCLASSEXTEND += "native"
SYSTEMD_SERVICE_${PN} += "wififw-mount.service"
