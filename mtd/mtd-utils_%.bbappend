SUMMARY = "Add support to ubinize"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS = "zlib e2fsprogs util-linux"

DEPENDS +="mtd-utils-native"

EXTRA_OECONF:class-native = "\
	--enable-static \
	--disable-shared \
        "
DISABLE_STATIC = ""

do_compile:class-native() {
        make -C ${S}../build CC="${BUILD_CC}" LDFLAGS=""  ubinize
}

do_install:append:class-native() {
	mkdir -p ${DEPLOY_DIR_IMAGE}
	install -m 755 ${WORKDIR}/build/ubinize ${DEPLOY_DIR_IMAGE}/
}

BBCLASSEXTEND = "native nativesdk"
