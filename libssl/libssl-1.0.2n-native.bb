SUMMARY = "Secure Socket Layer"
DESCRIPTION = "Secure Socket Layer (SSL) binary and related cryptographic tools."
HOMEPAGE = "http://www.openssl.org/"
BUGTRACKER = "http://www.openssl.org/news/vulnerabilities.html"
SECTION = "libs/network"

LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"



PV="3.7.2"

SRC_URI = "https://mirrors.sonic.net/pub/OpenBSD/LibreSSL/libressl-${PV}.tar.gz \
          "
S = "${WORKDIR}/libressl-${PV}"


SRC_URI[md5sum] = "4bd44489df291ad710512888599fbd25"
SRC_URI[sha256sum] = "b06aa538fefc9c6b33c4db4931a09a5f52d9d2357219afcbff7d93fe12ebf6f7"



inherit native

do_configure () {
	./config
}


do_install:class-native () {

        install -d ${D}/${includedir}
        install -d ${D}${STAGING_DIR_NATIVE}/usr/include/libressl-3.7.2/
        cp --dereference -R include/openssl ${D}/${includedir}
        cp --dereference -R  ${D}${STAGING_DIR_NATIVE}/usr/include/openssl ${D}${STAGING_DIR_NATIVE}/usr/include/libressl-3.7.2/
        cp ${S}/ssl/.libs/libssl.a  ${D}${STAGING_DIR_NATIVE}/usr/include/libressl-3.7.2/
        cp ${S}/crypto/.libs/libcrypto.a  ${D}${STAGING_DIR_NATIVE}/usr/include/libressl-3.7.2/

        rm -rf ${D}${STAGING_DIR_NATIVE}/usr/include/openssl
        rm -rf ${D}${STAGING_DIR_NATIVE}/usr/lib
        rm -rf ${D}${STAGING_DIR_NATIVE}/usr/bin
        rm -rf ${D}${STAGING_DIR_NATIVE}/usr/share

}

BBCLASSEXTEND = "native nativesdk"
