SUMMARY = "libcbor is a C library for parsing and generating CBOR, the general-purpose schema-less binary data format."
DESCRIPTION = "libcbor is a C library for parsing and generating CBOR, the general-purpose schema-less binary data format."
HOMEPAGE = "https://github.com/PJK/libcbor"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=6f3b3881df62ca763a02d359a6e94071"

SRC_URI = "https://github.com/PJK/libcbor/archive/refs/tags/v0.11.0.tar.gz;downloadfilename=libcbor-0.11.0.tar.gz"

SRC_URI[md5sum] = "dd39ecd3e3c7adf2eccc585e5c2c2265"
SRC_URI[sha256sum] = "89e0a83d16993ce50651a7501355453f5250e8729dfc8d4a251a78ea23bb26d7"

inherit cmake

S = "${WORKDIR}/libcbor-0.11.0"

EXTRA_OECMAKE += "-DBUILD_SHARED_LIBS=ON"

do_install() {
    install -d -m0755 ${D}/usr/lib
    cp ${WORKDIR}/build/src/libcbor.so* ${D}/usr/lib/

    install -d -m0755 ${D}/usr/include/
    cp ${S}/src/*.h ${D}/usr/include/

    install -d -m0755 ${D}/usr/include/cbor
    cp ${S}/src/cbor/*.h ${D}/usr/include/cbor/
    cp ${B}/src/cbor/*.h ${D}/usr/include/cbor/
    cp ${B}/cbor/*.h ${D}/usr/include/cbor/
}

FILES_${PN} = "/usr/lib/libcbor.so*"
FILES:${PN}-dev += "/usr/include/* /usr/include/cbor/*"

INSANE_SKIP_${PN} += "already-stripped"
SOLIBS = ".so"
FILES_SOLIBSDEV = ""
