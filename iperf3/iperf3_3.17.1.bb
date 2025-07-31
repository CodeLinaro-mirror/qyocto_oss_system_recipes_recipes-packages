SUMMARY = "Internet Protocol bandwidth measuring tool"
DESCRIPTION = "Iperf is a tool to measure maximum TCP bandwidth, allowing the tuning of various parameters and characteristics."
HOMEPAGE = "https://github.com/esnet/iperf"
LICENSE = "BSD-3-Clause & MIT & ISC & Public-Domain"
LIC_FILES_CHKSUM = "file://configure.ac;md5=30fe6756973369022049e7d1d07c9f5b"


SRC_URI += "https://downloads.es.net/pub/iperf/iperf-${PV}.tar.gz \
	file://010-y2k.patch \
	file://020-big-endian.patch \
"

SRC_URI[sha256sum] = "84404ca8431b595e86c473d8f23d8bb102810001f15feaf610effd3b318788aa"

inherit autotools pkgconfig

S = "${WORKDIR}/iperf-${PV}"

PACKAGECONFIG ??= ""
PACKAGECONFIG[ssl] = "--with-openssl, --without-openssl, openssl"

EXTRA_OECONF += "--without-sctp"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/src/.libs/iperf3 ${D}${bindir}/iperf3
}

PACKAGES =+ "${PN}-lib"
FILES:${PN}-lib = "${libdir}/libiperf.so.*"
