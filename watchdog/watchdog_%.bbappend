SUMMARY = "Enable watchdog service support"
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SYSTEMD_AUTO_ENABLE = "enable"

do_install_append() {
    sed -i '/After=multi-user.target/d' "${D}${systemd_system_unitdir}/wd_keepalive.service"
}
