DESCRIPTION = "Sysupgrade script"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

SRC_URI = "file://platform.sh \
           file://common.sh \
           file://do_stage2 \
	   file://sysupgrade \
	   file://sysupgrade.conf \
	"

S = "${WORKDIR}"

do_install() {
	install -d ${D}${base_libdir}/upgrade/
	install -d  ${D}/sbin
	install -d  ${D}/etc
	install -m 0755 ${WORKDIR}/platform.sh ${D}/lib/upgrade/platform.sh
	install -m 0755 ${WORKDIR}/common.sh ${D}/lib/upgrade/common.sh
	install -m 0755 ${WORKDIR}/do_stage2 ${D}/lib/upgrade/do_stage2
	install -m 755 ${S}/sysupgrade ${D}/sbin
	install -m 755 ${S}/sysupgrade.conf ${D}/etc
}

FILES_${PN} += "${libdir}/* ${baselib}/* ${sysconfdir}/* /sbin ${base_libdir}/upgrade/*"
