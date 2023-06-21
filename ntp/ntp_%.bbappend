FILESEXTRAPATHS_append := "${THISDIR}/file:"
SRC_URI_append += "file://ntp_append.conf"

do_install_append() {
	rm ${D}${systemd_unitdir}/system/ntpd.service
	cat ${WORKDIR}/ntp_append.conf >> ${D}/etc/ntp.conf
}
SYSTEMD_SERVICE_${PN}_remove = "ntpd.service"
