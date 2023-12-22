DESCRIPTION = "baridge-utils"
SECTION = "bridge-utils"
LICENSE = "GPLv2"
PR = "r0"
LIC_FILES_CHKSUM = "file://COPYING;md5=f9d20a453221a1b7e32ae84694da2c37"

inherit autotools-brokensep update-alternatives

SRC_URI = "https://codelinaro.jfrog.io/artifactory/codelinaro-qsdk/bridge-utils-1.6.tar.xz"
SRCREV = "b9841b03ed7403fc992e6216a5b08c74362b13e5"

SRC_URI[md5sum] = "541ae1c50cc268056693608920e6c908"

S = "${WORKDIR}/bridge-utils-1.6"

do_install:append() {
	install -d ${D}/usr/sbin
	install -m 0755 ${S}/brctl/brctl ${D}/usr/sbin
}
