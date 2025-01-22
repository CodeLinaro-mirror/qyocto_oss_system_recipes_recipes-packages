DESCRIPTION = "Button Hotplug Driver"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${WORKDIR}/gpio-button-hotplug.c;md5=6a849540aff2cad06ac9437dbf5c0c97"

inherit module

CLEANBROKEN = "1"

FILESEXTRAPATHS:prepend := "${THISDIR}/files/:"

SRC_URI = "file://Makefile \
	   file://gpio-button-hotplug.c \
	   "

DEPENDS = "virtual/kernel"

S = "${WORKDIR}/gpio-button-hotplug"

PACKAGES += "kernel-module-gpio-button-hotplug"
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
	install -m 0644 ../gpio-button-hotplug${KERNEL_OBJECT_SUFFIX} ${D}${base_libdir}/modules/${KERNEL_VERSION}/kernel/drivers/${PN}
}

KERNEL_MODULE_AUTOLOAD += "gpio-button-hotplug"
module_autoload_gpio-button-hotplug = "gpio-button-hotplug"
