DESCRIPTION = "baridge-utils"
SECTION = "bridge-utils"
LICENSE = "LGPLv2.0+"
PR = "r0"
LIC_FILES_CHKSUM = "file://COPYING;md5=f9d20a453221a1b7e32ae84694da2c37"

inherit autotools-brokensep update-alternatives

SRC_URI = "http://sourceforge.net/projects/bridge/files/bridge/bridge-utils-1.5.tar.gz"

SRC_URI[md5sum] = "ec7b381160b340648dede58c31bb2238"

S = "${WORKDIR}/bridge-utils-1.5"

do_install_append() {
	install -d ${D}/usr/sbin
	install -m 0755 ${S}/brctl/brctl ${D}/usr/sbin
}
