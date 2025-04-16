SUMMARY = "A console-only image for the RDK-B yocto build"

inherit rdk-image

IMAGE_FEATURES += "broadband"

IMAGE_ROOTFS_SIZE = "8192"

IMAGE_INSTALL_remove = " \
    packagegroup-base-extended \
"

IMAGE_INSTALL_append = " \
    packagegroup-rdk-oss-broadband \
    packagegroup-rdk-ccsp-broadband \
    rdk-logger \
"

IMAGE_INSTALL_append = " \
    vcpe-init \
"

IMAGE_INSTALL_append = " \
    strace \
    lsof \
"

do_rootfs[nostamp] = "1"
