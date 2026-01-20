DESCRIPTION = "Sysupgrade script"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = "file://platform.sh \
           file://common.sh \
           file://do_stage2 \
	   file://trymodedone \
	   file://sysupgrade \
	   file://sysupgrade.conf \
	   file://trymodedone.service \
	   file://ipq53xx/platform.sh \
	   file://ipq54xx/platform.sh \
	"

PLATFORMSCRIPTPATH:ipq95xx_64 = "${WORKDIR}/"
PLATFORMSCRIPTPATH:ipq53xx_64 = "${WORKDIR}/ipq53xx/"
PLATFORMSCRIPTPATH:ipq54xx_64 = "${WORKDIR}/ipq54xx/"
PLATFORMSCRIPTPATH:ipq52xx_64 = "${WORKDIR}/"
PLATFORMSCRIPTPATH:ipq96xx_64 = "${WORKDIR}/"

PLATFORMSCRIPTPATH:ipq95xx = "${WORKDIR}/"
PLATFORMSCRIPTPATH:ipq53xx = "${WORKDIR}/ipq53xx/"
PLATFORMSCRIPTPATH:ipq54xx = "${WORKDIR}/ipq54xx/"
PLATFORMSCRIPTPATH:ipq52xx = "${WORKDIR}/"
PLATFORMSCRIPTPATH:ipq96xx = "${WORKDIR}/"

inherit systemd

S = "${WORKDIR}"

do_install() {
	install -d ${D}${base_libdir}/upgrade/
	install -d  ${D}/sbin
	install -d  ${D}/etc
	install -d ${D}${systemd_unitdir}/system
	install -m 0755 ${PLATFORMSCRIPTPATH}/platform.sh ${D}/lib/upgrade/platform.sh
	install -m 0755 ${WORKDIR}/common.sh ${D}/lib/upgrade/common.sh
	install -m 0755 ${WORKDIR}/do_stage2 ${D}/lib/upgrade/do_stage2
	install -m 0755 ${WORKDIR}/trymodedone ${D}/lib/upgrade/trymodedone
	install -m 0755 ${WORKDIR}/trymodedone.service ${D}${systemd_unitdir}/system
	install -m 755 ${S}/sysupgrade ${D}/sbin
	install -m 755 ${S}/sysupgrade.conf ${D}/etc
}

FILES:${PN} += "${libdir}/* ${baselib}/* ${sysconfdir}/* /sbin ${base_libdir}/upgrade/* ${systemd_unitdir}/system/*"
SYSTEMD_SERVICE:${PN} += "trymodedone.service"

