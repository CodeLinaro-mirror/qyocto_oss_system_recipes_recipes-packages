SUMMARY = "JSON filter utility"
DESCRIPTION = "A utility for filtering JSON data"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

SRC_URI = "git://git.openwrt.org/project/jsonpath.git;protocol=git;branch=master"
SRCREV = "594cfa86469c005972ba750614f5b3f1af84d0f6"

PV = "1.0+git${SRCPV}"
S = "${B}"

SRC_URI[md5sum] = "2f455f04fbfcdb4c81cccd23475b47395f847db44aa4bd9a1007b9aa0ab7fd19"
SRC_URI[sha256sum] = "2f455f04fbfcdb4c81cccd23475b47395f847db44aa4bd9a1007b9aa0ab7fd19"

DEPENDS = "libubox json-c"

inherit cmake

do_configure:prepend() {
	cp -rf ${WORKDIR}/git/* ${B}/
}
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/jsonpath ${D}${bindir}/jsonfilter
}

FILES:${PN} = "${bindir}/jsonfilter"
