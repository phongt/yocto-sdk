# Fix GNU ld linker scripts in the Yocto SDK sysroot to use
# sysroot-relative paths (=/) instead of absolute paths (/).
#
# This is required for Bazel cross-compilation toolchains where
# the linker runs inside a sandbox and cannot resolve absolute
# paths like /lib/libm.so.6 from the host filesystem.
#
# Usage: inherit bazel_toolchain_patch  (in any image .bbappend)
#
# Background:
#   GNU ld treats "=/" prefix in linker scripts as:
#     <sysroot_path> + /lib/libm.so.6
#   Without "=", ld resolves /lib/libm.so.6 on the HOST,
#   which either doesn't exist or is the wrong architecture.

POPULATE_SDK_POST_TARGET_COMMAND:append = " bazel_sdk_fix;"

# SSH + root access for development
IMAGE_FEATURES += "ssh-server-openssh debug-tweaks"

bazel_sdk_fix() {
    SYSROOT="${SDK_OUTPUT}${SDKTARGETSYSROOT}"

    if [ ! -d "$SYSROOT" ]; then
        bbwarn "bazel_sdk_fix: sysroot not found at $SYSROOT, skipping"
        return 0
    fi

    bbnote "bazel_sdk_fix: patching GNU ld linker scripts in $SYSROOT"

    SEARCH_DIRS=""
    for d in \
        "$SYSROOT/lib"       \
        "$SYSROOT/lib64"     \
        "$SYSROOT/usr/lib"   \
        "$SYSROOT/usr/lib64" \
    ; do
        if [ -d "$d" ]; then
            SEARCH_DIRS="$SEARCH_DIRS $d"
        fi
    done

    if [ -z "$SEARCH_DIRS" ]; then
        bbwarn "bazel_sdk_fix: no lib directories found under $SYSROOT"
        return 0
    fi

    TMPLIST=$(mktemp)
    find $SEARCH_DIRS -maxdepth 1 -type f -name "*.so" > "$TMPLIST"

    while read f; do
        if ! file "$f" | grep -qE "ASCII|script|text"; then
            continue
        fi

        if ! grep -q "GROUP" "$f"; then
            continue
        fi

        if grep -q "( =/" "$f"; then
            bbdebug 1 "bazel_sdk_fix: already patched: $f"
            continue
        fi

        if ! grep -qE "\( /" "$f"; then
            continue
        fi

        bbnote "bazel_sdk_fix: patching $f"
        bbnote "bazel_sdk_fix: BEFORE: $(cat $f | tr -s '\n' ' ')"

        # Fix 1: paths after opening paren:   ( /lib   →  ( =/lib
        sed -i -E 's|\([ \t]+/|( =/|g' "$f"

        # Fix 2: paths after space only:   /usr/lib/x  →  =/usr/lib/x
        # only match / followed by a letter to avoid matching lone /
        sed -i -E 's|[ \t]+/([a-zA-Z])| =/\1|g' "$f"

        bbnote "bazel_sdk_fix: AFTER:  $(cat $f | tr -s '\n' ' ')"

    done < "$TMPLIST"

    rm -f "$TMPLIST"
    bbnote "bazel_sdk_fix: done"
}
