SUMMARY = "WASI SDK"
DESCRIPTION = "WebAssembly System Interface (WASI) SDK to build WAMR container"
HOMEPAGE = "https://github.com/WebAssembly/wasi-sdk"
LICENSE = "Apache-2.0 WITH LLVM-exception"
LIC_FILES_CHKSUM = "file://lib/clang/18/include/adcintrin.h;md5=c6b40df954b32a0edc2d764f92cae8ab"

SRC_URI = "https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-24/wasi-sdk-24.0-x86_64-linux.tar.gz"
SRC_URI[sha256sum] = "c6c38aab56e5de88adf6c1ebc9c3ae8da72f88ec2b656fb024eda8d4167a0bc5"

S = "${WORKDIR}/wasi-sdk-24.0-x86_64-linux"

do_compile() {
    # No compilation needed, just extraction
    echo "Setting up environment variables on host..."
    export WASI_SDK_INSTALLATION_DIR=${S}
    export CLANG="${S}/bin/clang --sysroot=${S}/share/wasi-sysroot"
    export CLANGXX="${S}/bin/clang++ --sysroot=${S}/share/wasi-sysroot"
}

FILES_${PN} += "${S}"
