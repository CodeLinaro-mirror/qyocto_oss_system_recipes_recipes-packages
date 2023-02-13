SUMMARY = "Software watchdog"
DESCRIPTION = "Watchdog is a daemon that checks if your system is still \
working. If programs in user space are not longer executed it will reboot \
the system."

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

do_install_append() {
    echo "interval = 15" >> ${WORKDIR}/watchdog.conf
    echo "watchdog-timeout = 32" >> ${WORKDIR}/watchdog.conf
    install -Dm 0644 ${WORKDIR}/watchdog.conf ${D}${sysconfdir}/watchdog.conf
}
