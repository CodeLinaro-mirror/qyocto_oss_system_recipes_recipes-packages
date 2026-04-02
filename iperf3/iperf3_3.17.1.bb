SUMMARY = "Internet Protocol bandwidth measuring tool"
DESCRIPTION = "Iperf is a tool to measure maximum TCP bandwidth, allowing the tuning of various parameters and characteristics."
HOMEPAGE = "https://github.com/esnet/iperf"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

SRC_URI += "\
	https://downloads.es.net/pub/iperf/iperf-${PV}.tar.gz \
	file://010-y2k.patch \
	file://020-big-endian.patch \
	file://001-iperf3_skip_rx_copy.patch \
	file://002-iperf3_sk_offload.patch \
	file://003-iperf3_udp_gso_gro.patch \
	file://004-iperf3_udp_gro_gso_dp.patch \
"

SRC_URI[sha256sum] = "84404ca8431b595e86c473d8f23d8bb102810001f15feaf610effd3b318788aa"

inherit autotools pkgconfig

S = "${WORKDIR}/iperf-${PV}"

PACKAGECONFIG ??= ""
PACKAGECONFIG[ssl] = "--with-openssl, --without-openssl, openssl"

EXTRA_OECONF += "--without-sctp"

# Enable NSS socket offload headers and ensure kernel module availability
CFLAGS:append = " -D_GNU_SOURCE -I${STAGING_INCDIR}/qca-nss-netfn"
RDEPENDS:${PN} += "kernel-module-qca-nss-netfn-sk-offload"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/src/.libs/iperf3 ${D}${bindir}/iperf3
}

PACKAGES += "${PN}-lib"
FILES:${PN}-lib += "${libdir}/libiperf.so.*"
