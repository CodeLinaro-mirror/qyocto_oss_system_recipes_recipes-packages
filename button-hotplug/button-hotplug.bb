DESCRIPTION = "Button Hotplug Driver"
LICENSE = "GPL-2-with-bison-exception"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=676cb7fcf1214ecbe3be420dd5a5b967"

inherit module

CLEANBROKEN = "1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files/:"

inherit systemd

SRC_URI = "file://Makefile \
	   file://button-hotplug.c \
	   file://restart-udevd.service \
	   "

DEPENDS = "virtual/kernel"

S = "${WORKDIR}/button-hotplug"

PACKAGES += "kernel-module-button-hotplug"
INSANE_SKIP:${PN} = "dev"

do_compile() {
	unset LDFLAGS
	make -C  "${STAGING_KERNEL_BUILDDIR}" \
		ARCH="${ARCH}" \
		CROSS_COMPILE='${TARGET_PREFIX}' \
		SUBDIRS="${S}/../" \
		M="${S}/../" \
		modules
}
do_install() {
	install -d ${D}${base_libdir}/modules/${KERNEL_VERSION}/kernel/drivers/${PN}
	install -m 0644 ../button-hotplug${KERNEL_OBJECT_SUFFIX} ${D}${base_libdir}/modules/${KERNEL_VERSION}/kernel/drivers/${PN}
	install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/restart-udevd.service  ${D}${systemd_unitdir}/system
}

KERNEL_MODULE_AUTOLOAD += "button-hotplug"
module_autoload_button-hotplug = "button-hotplug"
SYSTEMD_SERVICE:${PN} += "restart-udevd.service"
