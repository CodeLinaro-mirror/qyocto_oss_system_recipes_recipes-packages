SUMMARY = "Override recipe for procps package"
FILESEXTRAPATHS:prepend := "${THISDIR}/procps:"

SRC_URI += "file://sysctl.conf"

do_install:append() {
	install -m 0644 ${WORKDIR}/sysctl.conf ${D}${sysconfdir}/sysctl.conf
}	

