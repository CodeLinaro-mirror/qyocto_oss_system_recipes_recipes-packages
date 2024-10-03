DESCRIPTION = "Button Hotplug Driver"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${WORKDIR}/button-hotplug.c;md5=87abf2e5483c92f8909e9ab0143e3136"

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
