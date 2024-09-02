DESCRIPTION = "Sysupgrade script"
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = "file://platform.sh \
           file://common.sh \
           file://do_stage2 \
	   file://trymodedone \
	   file://sysupgrade \
	   file://sysupgrade.conf \
	   file://trymodedone.service \
	"
inherit systemd

S = "${WORKDIR}"

do_install() {
	install -d ${D}${base_libdir}/upgrade/
	install -d  ${D}/sbin
	install -d  ${D}/etc
	install -d ${D}${systemd_unitdir}/system
	install -m 0755 ${WORKDIR}/platform.sh ${D}/lib/upgrade/platform.sh
	install -m 0755 ${WORKDIR}/common.sh ${D}/lib/upgrade/common.sh
	install -m 0755 ${WORKDIR}/do_stage2 ${D}/lib/upgrade/do_stage2
	install -m 0755 ${WORKDIR}/trymodedone ${D}/lib/upgrade/trymodedone
	install -m 0755 ${WORKDIR}/trymodedone.service ${D}${systemd_unitdir}/system
	install -m 755 ${S}/sysupgrade ${D}/sbin
	install -m 755 ${S}/sysupgrade.conf ${D}/etc
}

FILES:${PN} += "${libdir}/* ${baselib}/* ${sysconfdir}/* /sbin ${base_libdir}/upgrade/* ${systemd_unitdir}/system/*"
SYSTEMD_SERVICE:${PN} += "trymodedone.service"

