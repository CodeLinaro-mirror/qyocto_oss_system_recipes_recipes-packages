SUMMARY = "QTI WIFI opensource package groups"
LICENSE = "BSD-3-Clause"
PACKAGE_ARCH = "${MACHINE_ARCH}"

RDEPENDS_packagegroup-qti-wifi += " \
        iw \
        uci \
	ipq-scripts \
        wireless-tools \
        qca-cnss \
        iperf \
	qca-sigma-dut \
        "

