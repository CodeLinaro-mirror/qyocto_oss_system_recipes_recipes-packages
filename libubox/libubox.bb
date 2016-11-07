DESCRIPTION = "libubox"
SECTION = "libubox"
LICENSE = "ISC"
PR = "r0"
LIC_FILES_CHKSUM = "file://utils.h;endline=17;md5=4d7fac50d952764bf582f5dc34d3b6b9"

DEPENDS = "json-c lua5.1"

inherit cmake pkgconfig

SRC_URI = "http://dev.gateworks.com/sources/libubox-2015-11-08-10429bccd0dc5d204635e110a7a8fae7b80d16cb.tar.gz "

SRC_URI[md5sum] = "16380cf88d298239a099233c10d8c0cc"

S = "${WORKDIR}/libubox-2015-11-08"

EXTRA_OECMAKE += '-DLIBARCH=${baselib} \
                 -DLUAPATH=/usr/lib/lua \
                 -DCMAKE_MODULE_LINKER_FLAGS:STRING="-L${STAGING_LIBDIR}" \
                 -DCMAKE_EXE_LINKER_FLAGS:STRING="-L${STAGING_LIBDIR}" \
                 -DCMAKE_SHARED_LINKER_FLAGS:STRING="-L${STAGING_LIBDIR}" \
                 -DCMAKE_FIND_ROOT_PATH=${STAGING_DIR_HOST}'

FILES_${PN} += "${libdir}/*"

FILES_${PN}-dbg += "${libdir}/lua/.debug"

FILES_${PN}-dev = "/usr/include/*"

INSANE_SKIP_${PN} = "dev-so"

BBCLASSEXTEND += "native"
