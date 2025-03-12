##########################################################################
# ============================================================================
# RDK MANAGEMENT, LLC CONFIDENTIAL AND PROPRIETARY
# ============================================================================
# This file (and its contents) are the intellectual property of RDK Management, LLC.
# It may not be used, copied, distributed or otherwise disclosed in whole or in
# part without the express written permission of RDK Management, LLC.
# ============================================================================
# Copyright (c) 2018 RDK Management, LLC. All rights reserved.
# ============================================================================
##########################################################################
MACHINEOVERRIDES =. "qemux86:"

PREFERRED_PROVIDER_virtual/gst-plugins-playersinkbin = "gst-plugins-playersinkbin-emulator"
PREFERRED_PROVIDER_virtual/iarmmgrs-hal = "iarmmgrs-hal-emulator"
PREFERRED_PROVIDER_virtual/devicesettings-hal = "devicesettings-hal-emulator"
PREFERRED_PROVIDER_virtual/closedcaption-hal = "closedcaption-hal"
PREFERRED_PROVIDER_virtual/rf4ce = "rf4ce-dummy"
PREFERRED_PROVIDER_virtual/mfrlib ?= "mfrlib-emulator"
PREFERRED_PROVIDER_virtual/tdksm = "tdksm-autotools"

# Qemu / RDK Emulator config
MACHINE_EXTRA_RDEPENDS += "vboxguestdrivers kernel-module-snd-intel8x0 kernel-module-vmwgfx"

APPEND_append_qemux86 = " quiet splash"

IMAGE_FSTYPES = "tar.gz wic.vmdk"

# OE 2.4 builds currently use wic to create vmdk images and wic depends on the
# GPLv3 grub-efi package by default when building for x86. Manually removing
# the dependency allows GPLv3 free builds to complete. To be reviewed.
WKS_FILE_DEPENDS_BOOTLOADERS_remove = "grub-efi"

SYSLINUX_ROOT = "root=/dev/hda2"

IMAGE_FEATURES = "read-only-rootfs"
DISTRO_FEATURES_append = " webconfig_bin"
DISTRO_FEATURES_append = " thunder_security_disable"
DISTRO_FEATURES_append = " gstreamer1_18"

# To fix issue with preferred version configuration from rdkv.inc has no effect
PREFERRED_VERSION_wpeframework = "${@bb.utils.contains('DISTRO_FEATURES', 'wpe_r4_4', '4.4%' , bb.utils.contains('DISTRO_FEATURES', 'wpe_r4', '4.2%', '2.1%', d), d)}"
PREFERRED_VERSION_wpeframework-clientlibraries = "${@bb.utils.contains('DISTRO_FEATURES', 'wpe_r4_4', '4.4%' , bb.utils.contains('DISTRO_FEATURES', 'wpe_r4', '4.2%', '2.1%', d), d)}"
PREFERRED_VERSION_wpeframework-interfaces = "${@bb.utils.contains('DISTRO_FEATURES', 'wpe_r4_4', '4.4%' , bb.utils.contains('DISTRO_FEATURES', 'wpe_r4', '4.2%', '2.1%', d), d)}"
PREFERRED_VERSION_wpeframework-tools-native = "${@bb.utils.contains('DISTRO_FEATURES', 'wpe_r4_4', '4.4%' , bb.utils.contains('DISTRO_FEATURES', 'wpe_r4', '4.2%', '2.1%', d), d)}"
