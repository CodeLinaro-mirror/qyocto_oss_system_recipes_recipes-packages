do_install_append() {
    rm  ${D}${systemd_unitdir}/system/sysstat.service
}
