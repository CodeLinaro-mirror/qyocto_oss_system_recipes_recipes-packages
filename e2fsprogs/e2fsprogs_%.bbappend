FILESEXTRAPATHS_append := "${THISDIR}/file:"
SRC_URI_append_class-native += "file://create-static-mke2fs.patch"

EXTRA_OECONF +=" --enable-libblkid"

do_install_prepend_class-native() {
	cp ${WORKDIR}/build/misc/mke2fs.static  ${D}/../build/misc/mke2fs
        cp ${WORKDIR}/build/misc/fsck.static  ${D}/../build/misc/fsck
}

do_populate_sysroot_append_class-native() {
    bb.build.exec_func("my_custom_function",d)
}

my_custom_function() {
    cp ${WORKDIR}/build/misc/fsck.static ${WORKDIR}/sysroot-destdir${STAGING_DIR_NATIVE}/sbin/fsck.ext2
    cp ${WORKDIR}/build/misc/fsck.static ${WORKDIR}/sysroot-destdir${STAGING_DIR_NATIVE}/sbin/fsck.ext3
    cp ${WORKDIR}/build/misc/fsck.static ${WORKDIR}/sysroot-destdir${STAGING_DIR_NATIVE}/sbin/fsck.ext4
}
