SUMMARY = "nl80211 based CLI configuration utility for wireless devices"
DESCRIPTION = "iw is a new nl80211 based CLI configuration utility for \
wireless devices. It supports almost all new drivers that have been added \
to the kernel recently. "
HOMEPAGE = "https://wireless.wiki.kernel.org/en/users/documentation/iw"
SECTION = "base"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://COPYING;md5=878618a5c4af25e9b93ef0be1a93f774"

DEPENDS = "libnl"

SRC_URI = "https://mirrors.edge.kernel.org/pub/software/network/iw/iw-${PV}.tar.xz \
		file://010-Revert-iw-allow-specifying-CFLAGS-LIBS-externally.patch \
		file://130-survey-bss-rx-time.patch \
		file://200-reduce_size.patch \
"

PATCH_DIR = "${TOPDIR}/../openwrt-patches/package/network/utils/iw/patches/"

SRC_URI[sha256sum] = "3f2db22ad41c675242b98ae3942dbf3112548c60a42ff739210f2de4e98e4894"

inherit pkgconfig

TARGET_CPPFLAGS += "-DIW_FULL"


EXTRA_OEMAKE = "\
	-f '${S}/Makefile' \
	\
	'PREFIX=${prefix}' \
	'SBINDIR=${sbindir}' \
	'MANDIR=${mandir}' \
	IW_FULL=1 \
"

do_custom_patch() {
    bbnote "Custom patch step: applying extra patches from ${PATCH_DIR} after SRC_URI patches"
    if [ ! -d "${PATCH_DIR}" ]; then
        bbfatal "PATCH_DIR does not exist: ${PATCH_DIR}"
    fi

    ls ${PATCH_DIR}/ | xargs -I % sh -c 'echo "Applying IW patch "%;patch -d${S} -p1 < ${PATCH_DIR}/%'
    patch -d${S} -p1 < ${THISDIR}/iw/0001-sawf_stats-add-inttypes.h-include-for-PRIu64.patch
}

addtask custom_patch after do_patch before do_configure

do_install() {
    oe_runmake 'DESTDIR=${D}' install
}
