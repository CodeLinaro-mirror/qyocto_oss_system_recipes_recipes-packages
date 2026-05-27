DESCRIPTION = "Enable Wi-Fi Firmware Mounting Service and Script into the image"
SECTION = "wififw-mount"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}/files:"

inherit systemd

SRC_URI = " \
    file://wififw-mount.service \
    file://wififw-mount.sh \
"

S = "${WORKDIR}/wififw-mount"

do_install:append() {
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/wififw-mount.sh ${D}${bindir}

        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/wififw-mount.service  ${D}${systemd_unitdir}/system
}
do_install:append:echo() {
	if ! grep -q '^After=systemrw.mount$' ${D}${systemd_unitdir}/system/wififw-mount.service; then
		sed -i '/^Before=ipq-boot.service$/a After=systemrw.mount' ${D}${systemd_unitdir}/system/wififw-mount.service
	fi
}

FILES:${PN} += " ${bindir}/*  ${systemd_unitdir}/system/*"
BBCLASSEXTEND += "native"
SYSTEMD_SERVICE:${PN} += "wififw-mount.service"
