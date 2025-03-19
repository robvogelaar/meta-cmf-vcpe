FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

do_patch[noexec] = "1"

SRC_URI += "file://0001-add-missing-pclose.patch"

do_custom_patches() {
    cd ${S}/devices_rpi/source/hal-ethsw
    bbnote "Current directory: $(pwd)"

    if [ -f ${WORKDIR}/0001-add-missing-pclose.patch ]; then
        if [ ! -e patch_applied ]; then
            bbnote "Applying patch: 0001-add-missing-pclose.patch"
            patch -p3 < ${WORKDIR}/0001-add-missing-pclose.patch
            touch patch_applied
        else
            bbnote "Patch already applied, skipping"
        fi
    else
        bbnote "Warning: Patch file 0001-add-missing-pclose.patch not found"
    fi
}

addtask do_custom_patches after do_configure before do_compile
