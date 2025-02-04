UNPACKDIR = "${WORKDIR}"

do_install:append() {
	install -m 0644 ${S}/include/gpsdclient.h ${D}/usr/include/
}
