do_install_append() {
	rm ${D}${systemd_unitdir}/system/ntpd.service
}
SYSTEMD_SERVICE_${PN}_remove = "ntpd.service"
