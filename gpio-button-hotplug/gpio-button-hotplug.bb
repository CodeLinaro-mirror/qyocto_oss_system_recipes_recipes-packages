DESCRIPTION = "GPIO Button Hotplug Driver"
LICENSE = "GPL-2-with-bison-exception"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=676cb7fcf1214ecbe3be420dd5a5b967"

inherit module

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
