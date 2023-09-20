FILESEXTRAPATHS_append := "${THISDIR}/file:"

EXTRA_OECONF +=" --enable-libblkid"

LDFLAGS_class-native += " -L${WORKDIR}/sysroot-destdir${STAGING_DIR_NATIVE}/usr/lib/ -Wl,-rpath-link,${WORKDIR}/sysroot-destdir${STAGING_DIR_NATIVE}/usr/lib/ -Wl,-rpath,${WORKDIR}/sysroot-destdir${STAGING_DIR_NATIVE}/usr/lib/  -L${STAGING_LIBDIR_NATIVE}/ -Wl,-rpath-link,${STAGING_LIBDIR_NATIVE}/ -Wl,-rpath,${STAGING_LIBDIR_NATIVE}/ "

do_populate_sysroot_append_class-native() {
    bb.build.exec_func("my_custom_function",d)
}

my_custom_function() {
    cp ${WORKDIR}/build/misc/mke2fs ${WORKDIR}/sysroot-destdir${STAGING_DIR_NATIVE}/sbin/mkfs.ext4
    cp ${WORKDIR}/build/e2fsck/e2fsck ${WORKDIR}/sysroot-destdir${STAGING_DIR_NATIVE}/sbin/e2fsck
}
