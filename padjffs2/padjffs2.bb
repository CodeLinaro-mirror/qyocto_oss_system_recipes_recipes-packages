DESCRIPTION = "padjffs2 utility"
SECTION = "utils"
LICENSE = "GPL-2.0+"

LIC_FILES_CHKSUM = "file://Makefile;md5=e89ab0c8f63fd18af7b1513286089705"
PR = "r0"

inherit autotools

SRC_URI = "file://build"

S = "${WORKDIR}/build"

do_compile() {
        make -f ${S}/Makefile
}

do_install() {
	mkdir -p ${DEPLOY_DIR_IMAGE}
	install -m 755 ${S}/padjffs2 ${DEPLOY_DIR_IMAGE}/padjffs2
}

BBCLASSEXTEND += "native"
