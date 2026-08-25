DESCRIPTION = "Validates the selected mem-profile at boot against physical MemTotal. \
Auto-corrects to the maximum profile allowed by the hardware and \
triggers a reboot if an incompatible profile is detected. \
Runs after u-boot-fw-utils.service so fw_setenv is usable."
SECTION = "base"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

SRC_URI = " \
    file://etc/init.d/mem-profile \
    file://etc/board.d/03_mem_profile \
    file://mem-profile.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "mem-profile.service"

do_install() {
    # Install the init script to /usr/lib/mem-profile/ so it survives
    # the systemd class rm_sysvinit_initddir purge of /etc/init.d/
    install -d ${D}${libdir}/mem-profile
    install -m 0755 ${WORKDIR}/etc/init.d/mem-profile \
        ${D}${libdir}/mem-profile/mem-profile

    install -d ${D}${sysconfdir}/board.d
    install -m 0755 ${WORKDIR}/etc/board.d/03_mem_profile \
        ${D}${sysconfdir}/board.d/03_mem_profile

    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/mem-profile.service \
        ${D}${systemd_unitdir}/system/mem-profile.service
}

FILES:${PN} += " \
    ${libdir}/mem-profile/mem-profile \
    ${sysconfdir}/board.d/03_mem_profile \
    ${systemd_unitdir}/system/mem-profile.service \
"