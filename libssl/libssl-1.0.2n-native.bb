SUMMARY = "Secure Socket Layer"
DESCRIPTION = "Secure Socket Layer (SSL) binary and related cryptographic tools."
HOMEPAGE = "http://www.openssl.org/"
BUGTRACKER = "http://www.openssl.org/news/vulnerabilities.html"
SECTION = "libs/network"

LICENSE = "openssl"
LIC_FILES_CHKSUM = "file://LICENSE;md5=057d9218c6180e1d9ee407572b2dd225"

PV="1.0.2n"

SRC_URI = "http://www.openssl.org/source/openssl-${PV}.tar.gz \
          "
S = "${WORKDIR}/openssl-${PV}"


SRC_URI[md5sum] = "13bdc1b1d1ff39b6fd42a255e74676a4"
SRC_URI[sha256sum] = "370babb75f278c39e0c50e8c4e7493bc0f18db6867478341a832a982fd15a8fe"


CFLAG = "${@oe.utils.conditional('SITEINFO_ENDIANNESS', 'le', '-DL_ENDIAN', '-DB_ENDIAN', d)} \
         ${TERMIO} ${CFLAGS} -Wall -Wa,--noexecstack"
CFLAG_append_class-native = " -fPIC"

export DIRS = "crypto ssl apps"
export EX_LIBS = "-lgcc -ldl"
export AS = "${CC} -c"
export DIRS = "crypto ssl apps engines"
export OE_LDFLAGS="${LDFLAGS}"

inherit native pkgconfig siteinfo multilib_header relative_symlinks

CONFFILES_openssl-conf = "${sysconfdir}/ssl/openssl.cnf"

# Remove this to enable SSLv3. SSLv3 is defaulted to disabled due to the POODLE
# vulnerability
EXTRA_OECONF = " -no-ssl3"

do_configure () {
        cd util
        perl perlpath.pl ${STAGING_BINDIR_NATIVE}
        cd ..
        ln -sf apps/openssl.pod crypto/crypto.pod ssl/ssl.pod doc/

        os=${HOST_OS}
        case $os in
        linux-gnueabi |\
        linux-musl*)
                os=linux
                ;;
                *)
                ;;
        esac
        target="$os-${HOST_ARCH}"
        echo "target=$target"
        case $target in
        linux-gnux32-x86_64)
                target=linux-x32
                ;;
        linux-gnu64-x86_64)
                target=linux-x86_64
                ;;
        esac
        # inject machine-specific flags
        sed -i -e "s|^\(\"$target\",\s*\"[^:]\+\):\([^:]\+\)|\1:${CFLAG}|g" Configure
        useprefix=${prefix}
        if [ "x$useprefix" = "x" ]; then
                useprefix=/
        fi
        perl ./Configure ${EXTRA_OECONF} shared --prefix=$useprefix --openssldir=${libdir}/ssl --libdir=`basename ${libdir}` $target
}

do_compile_prepend_class-target () {
    sed -i 's/\((OPENSSL=\)".*"/\1"openssl"/' Makefile
}

do_install_class-native () {
        # Create ${D}/${prefix} to fix parallel issues
        mkdir -p ${D}/${prefix}/
        oe_runmake INSTALL_PREFIX="${D}" MANDIR="${mandir}" install

        install -d ${D}/${includedir}
        install -d ${D}${STAGING_DIR_NATIVE}/usr/include/libssl-1.0.2n
        cp --dereference -R include/openssl ${D}/${includedir}
        cp --dereference -R  ${D}${STAGING_DIR_NATIVE}/usr/include/openssl ${D}${STAGING_DIR_NATIVE}/usr/include/libssl-1.0.2n/
        cp libssl.a  ${D}${STAGING_DIR_NATIVE}/usr/include/libssl-1.0.2n/
        cp libcrypto.a  ${D}${STAGING_DIR_NATIVE}/usr/include/libssl-1.0.2n/

        rm -rf ${D}${STAGING_DIR_NATIVE}/usr/include/openssl
        rm -rf ${D}${STAGING_DIR_NATIVE}/usr/lib
        rm -rf ${D}${STAGING_DIR_NATIVE}/usr/bin
        rm -rf ${D}${STAGING_DIR_NATIVE}/usr/share

}

BBCLASSEXTEND = "native nativesdk"
