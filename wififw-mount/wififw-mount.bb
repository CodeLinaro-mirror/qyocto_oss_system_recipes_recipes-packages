DESCRIPTION = "Enable Wi-Fi Firmware Mounting Service and Script into the image"
SECTION = "wififw-mount"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}/files:"
FILESEXTRAPATHS:prepend := "${TOPDIR}/../wifi/qca-wifi-files/net/qca-wifi/files/:"

inherit systemd

SRC_URI = " \
    file://wififw-mount.service \
    file://wififw-mount.sh \
    file://coredump.sh \
    file://init-wifi.sh \
    file://load-fig-fw.sh \
"

S = "${WORKDIR}/wififw-mount"

do_install:append() {
	install -d ${D}/lib/
	install -d ${D}/lib/wifi
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/wififw-mount.sh ${D}${bindir}

        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/wififw-mount.service  ${D}${systemd_unitdir}/system
	# Install pre-systemd init wrapper
	install -d ${D}${base_sbindir}
	install -m 0755 ${WORKDIR}/init-wifi.sh ${D}${base_sbindir}/init-wifi
	# Install shared FIG firmware bind-mount + fig_v2 modprobe helper,
	# used by init-wifi, wififw-mount.sh, and directly from the shell
	install -m 0755 ${WORKDIR}/load-fig-fw.sh ${D}${base_sbindir}/load-fig-fw
	# Pre-create /lib/firmware/fig and IPQ5424/WIFI_FW so bind mount works before overlay is ready
	install -d ${D}/lib/firmware/fig
	install -d ${D}/lib/firmware/IPQ5424/WIFI_FW
	# Copy Memdump collection script
	sed -i 's|SERVER=\$(fw_printenv serverip \| cut -c10-24);|SERVER=\$\(\/sbin\/fw_printenv serverip \| cut -c10-24\);|' ${WORKDIR}/coredump.sh
	sed -i 's|\$(tftp -l \$DUMPPATH -r \$FILENAME -p \$SERVER 2>\&1)|/usr/bin/tftp -l \$DUMPPATH -r \$FILENAME -p \$SERVER 2>\&1|' ${WORKDIR}/coredump.sh
	install -m 0755 ${WORKDIR}/coredump.sh ${D}/lib/wifi/00-q6dump
}

FILES:${PN} += " ${bindir}/* /lib/wifi/* ${systemd_unitdir}/system/* /lib/firmware/fig /lib/firmware/IPQ5424/WIFI_FW /lib/firmware/IPQ5424 ${base_sbindir}/init-wifi ${base_sbindir}/load-fig-fw"
BBCLASSEXTEND += "native"
SYSTEMD_SERVICE:${PN} += "wififw-mount.service"
