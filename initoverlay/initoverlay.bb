DESCRIPTION = "initoverlay scripts to mount rootfs_data partition as overlay"
SECTION = "initoverlay"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

PR = "r0"

inherit update-rc.d

SRC_URI = "file://initoverlay"

S = "${WORKDIR}/initoverlay"

do_install_append() {
	mkdir -p ${D}/rom
	mkdir -p ${D}/overlay
	install -d ${D}/etc/init.d/
	install -d ${D}/etc/profile.d/
	install -d ${D}${base_libdir}/functions/
	install -d ${D}${base_libdir}/initoverlay/
	install -d ${D}/sbin/

	install -m 0755 ${WORKDIR}/initoverlay/lib/functions/boot.sh ${D}/lib/functions/boot.sh
	install -m 0755 ${WORKDIR}/initoverlay/lib/initoverlay/check_overlay.sh ${D}/lib/initoverlay/check_overlay.sh
	install -m 0755 ${WORKDIR}/initoverlay/lib/initoverlay/mount_overlay.sh ${D}/lib/initoverlay/mount_overlay.sh
	install -m 0755 ${WORKDIR}/initoverlay/lib/initoverlay/pivot_overlay.sh ${D}/lib/initoverlay/pivot_overlay.sh
	install -m 0755 ${WORKDIR}/initoverlay/etc/init.d/initoverlay ${D}/etc/init.d/initoverlay
	install -m 0755 ${WORKDIR}/initoverlay/etc/profile.d/overlay.sh ${D}/etc/profile.d/overlay.sh
	install -m 0755 ${WORKDIR}/initoverlay/sbin/jffs2reset ${D}/sbin/jffs2reset
}

FILES_${PN} += "${libdir}/* ${baselib}/* ${sysconfdir}/* /rom /overlay /sbin"

BBCLASSEXTEND += "native"

INITSCRIPT_PACKAGES = "initoverlay"
INITSCRIPT_NAME = "initoverlay"
INITSCRIPT_PARAMS = "start 10 S . stop 70 0 6 1 ."
