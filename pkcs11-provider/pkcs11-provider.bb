SUMMARY = "PKCS11 library"
DESCRIPTION = "OpenSSL 3.x provider to access Hardware and Software Tokens using the PKCS#11 Cryptographic Token Interface."
HOMEPAGE = "https://github.com/latchset/pkcs11-provider"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "git://github.com/latchset/pkcs11-provider.git;protocol=https;branch=main"
SRCREV = "8f6b94409d4872265076df310492da1e5f6abdf7"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

inherit meson pkgconfig
DEPENDS += " openssl "

do_install() {
    install -d ${D}/usr/lib/engines-3/
    install -m 0755 ${B}/src/pkcs11.so ${D}/usr/lib/engines-3/
}

FILES_${PN} += " /usr/lib/engines-3/ /usr/lib/engines-3/* "
