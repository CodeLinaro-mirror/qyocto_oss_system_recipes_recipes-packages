SYSTEMD_SERVICE:${PN}:remove ="sysstat.service"

do_install:append() {
    rm  ${D}${systemd_system_unitdir}/sysstat.service
}
