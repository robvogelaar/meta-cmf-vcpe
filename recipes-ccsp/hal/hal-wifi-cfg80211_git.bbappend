FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI += "file://0001-Add-missing-functions-as-stubs.patch"

do_custom_patches() {
    cd ${S}
    bbnote "Current directory: $(pwd)"
    
    if [ -f ${WORKDIR}/0001-Add-missing-functions-as-stubs.patch ]; then
        if [ ! -e patch_applied ]; then
            bbnote "Applying patch: 0001-Add-missing-functions-as-stubs.patch"
            patch -p3 < ${WORKDIR}/0001-Add-missing-functions-as-stubs.patch
            touch patch_applied
        else
            bbnote "Patch already applied, skipping"
        fi
    else
        bbnote "Warning: Patch file 0001-Add-missing-functions-as-stubs.patch not found"
    fi
}

addtask do_custom_patches after do_unpack before do_compile
