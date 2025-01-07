LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${WORKDIR}/Makefile;md5=2d9ebf7c55a20fe03a778f358116530b"

CLEANBROKEN = "1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files/:"

SRC_URI = "file://Makefile \
           file://gps_client.c \
           "
S = "${WORKDIR}/"

DEPENDS += " gpsd "

TARGET_CFLAGS += "-FPIC"
TARGET_LDFLAGS += "-L${STAGING_DIR}/usr/lib -lgps"

do_compile() {
        make -C  "${S}" CC="${CC}" CFLAGS="${TARGET_CFLAGS}" LDFLAGS="${TARGET_LDFLAGS}"
}

do_install() {
        install -d ${D}/usr/sbin
        install -m 0644 ${S}/gpsclient ${D}/usr/sbin/
}


