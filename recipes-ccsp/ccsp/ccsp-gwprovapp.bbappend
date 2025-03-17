FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "file://0001-no-autoconf.h.patch"

do_custom_patches() {
    cd ${S}
    bbnote "Current directory: $(pwd)"

    if [ -f ${WORKDIR}/0001-no-autoconf.h.patch ]; then
        if [ ! -e patch_applied ]; then
            bbnote "Applying patch: 0001-no-autoconf.h.patch"
            patch -p1 < ${WORKDIR}/0001-no-autoconf.h.patch
            touch patch_applied
        else
            bbnote "Patch already applied, skipping"
        fi
    else
        bbnote "Warning: Patch file 0001-no-autoconf.h.patch not found"
    fi
}

addtask do_custom_patches after do_unpack before do_compile
