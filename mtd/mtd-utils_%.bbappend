SUMMARY = "Add support to ubinize"
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

DEPENDS = "zlib e2fsprogs util-linux"

DEPENDS +="mtd-utils-native"

EXTRA_OECONF_class-native = "\
	--enable-static \
	--disable-shared \
        "
DISABLE_STATIC = ""

do_compile_class-native() {
        make -C ${S}../build CC="${BUILD_CC}" LDFLAGS=""  ubinize
}

do_install_append_class-native() {
	mkdir -p ${DEPLOY_DIR_IMAGE}
	install -m 755 ${WORKDIR}/build/ubinize ${DEPLOY_DIR_IMAGE}/
}

BBCLASSEXTEND = "native nativesdk"
