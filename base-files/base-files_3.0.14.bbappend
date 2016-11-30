
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://fstab \
           "

do_install_append() {
	install -d ${D}/${sysconfdir}
	install -m 0644 ${WORKDIR}/fstab ${D}${sysconfdir}/fstab
}



