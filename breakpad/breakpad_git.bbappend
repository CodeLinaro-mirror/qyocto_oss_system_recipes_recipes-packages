FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " ${@bb.utils.contains('RDK_RELEASE', 'rdkb-2023q1-dunfell', 'file://patches/0002-fix-build-with-ubuntu22.patch', '', d)}"
