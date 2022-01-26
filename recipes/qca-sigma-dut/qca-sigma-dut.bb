DESCRIPTION = "A control agent for automating Wi-Fi Alliance certification tests"
LICENSE = "Clear BSD"
LIC_FILES_CHKSUM = "file://CONTRIBUTIONS;md5=197d865603c600e1bb18c4d95f890b30"

FILESPATH =+ "${TOPDIR}/../src/ipq:"

SRC_URI = "git://github.com/qca/sigma-dut.git;rev=77dda64736bb372cb56df00d2e6601cdf8e6e971 \
	   file://qca-sigma-dut/sigma-dut \
	   "
DEPENDS = "libpthread-stubs"

S = "${WORKDIR}/git/"
B = "${WORKDIR}/qca-sigma-dut/sigma-dut"

FILES_${PN} += "/usr/sbin/* /usr/sbin/ipq/*"
FILES_${PN} += "/etc/init.d/*"
FILES_${PN} += "/etc/config/*"

LC_ALL="C"

TARGET_CPPFLAGS = "-Wno-format-truncation"

do_patch() {
	ls ${B}/patches | xargs -I % sh -c 'patch -d${S} -p1 < ${B}/patches/%'
}

do_compile() {
	CFLAGS="${TARGET_CFLAGS} ${TARGET_CPPFLAGS} -DCONFIG_BUILD_YOCTO=y" \
	make -C ${S} all
}

do_install() {
	install -d ${D}/usr/sbin
	install -d ${D}/usr/sbin/ipq
	install -d ${D}/etc/init.d
	install -d ${D}/etc/config

	install -m 0755 ${S}/sigma_dut ${D}/usr/sbin/ipq
	ln -sf /systemrw/wlan/bin/sigma_dut ${D}/usr/sbin/sigma_dut
	install -m 0755 ${B}/files/sigma_dut.init ${D}/etc/init.d/sigma-dut
	install -m 0666 ${B}/files/sigma-dut.config ${D}/etc/config/sigma-dut
}
