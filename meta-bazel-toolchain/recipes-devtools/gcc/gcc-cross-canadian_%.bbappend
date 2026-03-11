#
# Install gcov.h into the GCC internal include directory in the SDK.
# Reference: poky/meta/recipes-devtools/gcc/gcc-cross-canadian.inc
#
# Key variables from gcc-cross-canadian.inc:
#   BINV        = GCC binary version (e.g. "13.4.0")
#   TARGET_SYS  = target tuple (e.g. "x86_64-poky-linux")
#   libdir      = ${prefix}/lib  (SDK host prefix)
#   libexecdir  = ${prefix}/libexec


do_install:append() {
    GCC_INCLUDE_DIR="${D}${libdir}/gcc/${TARGET_SYS}/${BINV}/include"

    bbnote "gcc-cross-canadian bbappend: BINV=${BINV}"
    bbnote "gcc-cross-canadian bbappend: TARGET_SYS=${TARGET_SYS}"
    bbnote "gcc-cross-canadian bbappend: GCC include dir=${GCC_INCLUDE_DIR}"
    bbnote "gcc-cross-canadian bbappend: S=${S}"
    bbnote "gcc-cross-canadian bbappend: B=${B}"

    if [ ! -d "${GCC_INCLUDE_DIR}" ]; then
        bbwarn "gcc-cross-canadian bbappend: include dir not found: ${GCC_INCLUDE_DIR}"
        return 0
    fi

    if [ -f "${GCC_INCLUDE_DIR}/gcov.h" ]; then
        bbnote "gcc-cross-canadian bbappend: gcov.h already present, skipping"
        return 0
    fi

    # Search in multiple candidate locations
    GCOV_SRC=""
    for candidate in \
        "${S}/libgcc/gcov.h"            \
        "${S}/gcc/gcov.h"               \
        "${S}/gcc/ginclude/gcov.h"      \
        "${B}/gcc/gcov.h"               \
        "${B}/gcc/include/gcov.h"       \
    ; do
        bbnote "gcc-cross-canadian bbappend: checking ${candidate}"
        if [ -f "${candidate}" ]; then
            GCOV_SRC="${candidate}"
            bbnote "gcc-cross-canadian bbappend: found gcov.h at ${GCOV_SRC}"
            break
        fi
    done

    if [ -z "${GCOV_SRC}" ]; then
        # Last resort — find anywhere under S
        GCOV_SRC=$(find "${S}" -name "gcov.h" ! -path "*/testsuite/*" \
            -type f 2>/dev/null | head -1)
        bbnote "gcc-cross-canadian bbappend: find result: ${GCOV_SRC}"
    fi

    if [ -z "${GCOV_SRC}" ]; then
        bbwarn "gcc-cross-canadian bbappend: gcov.h not found anywhere under S=${S}"
        return 0
    fi

    bbnote "gcc-cross-canadian bbappend: installing gcov.h from ${GCOV_SRC}"
    install -m 0644 "${GCOV_SRC}" "${GCC_INCLUDE_DIR}/gcov.h"
}

PACKAGES:append = " gcc-cross-canadian-gcov-dev"

FILES:gcc-cross-canadian-gcov-dev = "\
    ${libdir}/gcc/${TARGET_SYS}/${BINV}/include/gcov.h \
"

SUMMARY:gcc-cross-canadian-gcov-dev = "GCC gcov header for SDK"
ALLOW_EMPTY:gcc-cross-canadian-gcov-dev = "1"
