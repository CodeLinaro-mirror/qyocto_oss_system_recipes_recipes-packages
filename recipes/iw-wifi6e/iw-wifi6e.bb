DESCRIPTION = "cfg80211 interface configuration utility"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://COPYING;md5=878618a5c4af25e9b93ef0be1a93f774"

FILESEXTRAPATHS_prepend := "${THISDIR}/:"

PV = "6.9"
SRC_URI = "https://www.kernel.org/pub/software/network/iw/iw-${PV}.tar.xz \
	   file://patches \
	   "
SRC_URI[md5sum] = "457c99badf2913bb61a8407ae60e4819"
SRC_URI[sha256sum] = "3f2db22ad41c675242b98ae3942dbf3112548c60a42ff739210f2de4e98e4894"

DEPENDS = "libnl"
S = "${WORKDIR}/iw-${PV}"

TARGET_CFLAGS += "-fpie -Wall -Werror -Wno-error=sign-compare"
TARGET_LDFLAGS += "-pie -L${STAGING_LIBDIR}"
TARGET_CPPFLAGS = "-I${STAGING_INCDIR}/libnl3 \
		   ${TAGET_CPPFLAGS} \
		   -DCONFIG_LIBNL20 \
		   -D_GNU_SOURCE"

inherit pkgconfig

do_configure() {
	echo "const char iw_version[] = \"${PV}\";" > ${S}/version.c
	rm -f ${S}/version.sh
	touch ${S}/version.sh
	chmod +x ${S}/version.sh
}

do_patch() {
	ls ${WORKDIR}/patches | xargs -I % sh -c 'patch -d${S} -p1 < ${WORKDIR}/patches/%'
}

do_compile_prepend() {
	CFLAGS="${TARGET_CPPFLAGS} ${TARGET_CFLAGS} -ffunction-sections -fdata-sections" \
	LDFLAGS="${TARGET_LDFLAGS} -Wl,--gc-sections" \
	export NL1FOUND="" \
	export NL2FOUND="" \
	export NL3FOUND="" \
	export NL31FOUND="" \
	export NL3xFOUND="Y" \
	export NLLIBNAME="libnl3" \
	LIBS="-lm -lnl-3" \
	export V=1
}

do_install() {
	install -d ${D}/usr/sbin
	install -m 0755 ${S}/iw ${D}/usr/sbin/
}

FILES_${PN} += "/usr/sbin/*"
