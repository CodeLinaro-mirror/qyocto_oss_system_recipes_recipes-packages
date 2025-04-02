SUMMARY = "Library implementing the WebAssembly Micro Runtime"
DESCRIPTION = "WebAssembly Micro Runtime (WAMR) is a lightweight standalone WebAssembly (Wasm) runtime with small footprint, high performance and highly configurable features for applications cross from embedded, IoT, edge to Trusted Execution Environment (TEE), smart contract, cloud native and so on."
HOMEPAGE = "https://github.com/bytecodealliance/wasm-micro-runtime"
LICENSE = "Apache-2.0-with-LLVM-exception"
LIC_FILES_CHKSUM = "file://LICENSE;md5=9bac531f750f8b679d03181996ba09a1"

SRC_URI = "https://codelinaro.jfrog.io/artifactory/codelinaro-qsdk/WAMR-1.3.2.tar.gz"
SRC_URI[md5sum] = "2162342ef51926b4a1dda036e4b4595b"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-enable-pthread.patch"

FILES_SOLIBSDEV = ""

S = "${WORKDIR}/wasm-micro-runtime-WAMR-${PV}"
PV = "1.3.2"

inherit cmake

do_install() {
    install -d ${D}${includedir}/libwamr
    install -d ${STAGING_DIR}${includedir}/libwamr
    install -m 0644 ${S}/core/iwasm/include/*.h ${D}${includedir}/libwamr/
    cp ${D}${includedir}/libwamr/lib_export.h ${STAGING_DIR}${includedir}
    cp ${D}${includedir}/libwamr/wasm_export.h ${STAGING_DIR}${includedir}
    cp ${D}${includedir}/libwamr/*.h ${STAGING_DIR}${includedir}/libwamr
    install -d ${D}${libdir}
    install -m 0644 ${B}/libiwasm.so ${D}${libdir}/
    install -d ${D}${bindir}
    install -m 0755 ${B}/product-mini/platforms/linux/iwasm ${D}${bindir}/
}

FILES:${PN} = "${includedir}/libwamr ${libdir}/libiwasm.so ${bindir}/iwasm"
FILES_${PN}-dev =" "
INSANE_SKIP:${PN}-dev += "dev-elf"
