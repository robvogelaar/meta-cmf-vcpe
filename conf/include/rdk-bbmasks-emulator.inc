#
# ============================================================================
# RDK MANAGEMENT, LLC CONFIDENTIAL AND PROPRIETARY
# ============================================================================
# This file (and its contents) are the intellectual property of RDK Management, LLC.
# It may not be used, copied, distributed or otherwise  disclosed in whole or in
# part without the express written permission of RDK Management, LLC.
# ============================================================================
# Copyright (c) 2015 RDK Management, LLC. All rights reserved.
# ============================================================================
#

BBMASK .= "|meta/recipes-connectivity/bluez/bluez-hcidump_2.5.bb"
BBMASK .= "|meta/recipes-connectivity/bluez/bluez4_4.101.bb"

BBMASK .= "|meta-rdk-ext/recipes-support/icu"
BBMASK .= "|meta-rdk.*/recipes-extended/podmgr"

## Mask recipes from meta-rdk-comcast layer ##
BBMASK .= "${@bb.utils.contains('DISTRO_FEATURES', 'lean_emulator', '\
|meta-rdk-comcast/recipes-benchmark/ \
|meta-rdk-comcast/recipes-qt/secapi/secapi-common-hw_git.bb \
|meta-rdk-comcast/recipes-qt/secapi/secapi2-adapter_git.bb \
|meta-rdk-comcast/recipes-connectivity/ \
|meta-rdk-comcast/recipes-core/ \
|meta-rdk-comcast/recipes-extended/ \
|meta-rdk-comcast/recipes-oem/ \
|meta-rdk-comcast/recipes-test/ \
|meta-rdk-comcast/recipes-common/ \
|meta-rdk-comcast/recipes-containers/ \
|meta-rdk-comcast/recipes-devtools/ \
|meta-rdk-comcast/recipes-kernel/ \
|meta-rdk-comcast/recipes-protocols/ \
|meta-rdk-comcast/recipes-support/ \
|meta-rdk-comcast/recipes-tweaks/ \
','', d)}"


## MASK recipes from meta-rdk-comcast-video layer ##
BBMASK .= "${@bb.utils.contains('DISTRO_FEATURES', 'lean_emulator', '\
|meta-rdk-comcast-video/recipes-extended/wpe-framework/rdkservices_git.bbappend \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework_%.bbappend \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework-clientlibraries_%.bbappend \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework-interfaces_%.bbappend \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework-ocdm-playready_git.bb \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework-ocdm-playready-rdk_git.bb \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework-ocdm-widevine2_git.bb \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework-ocdm-widevine_git.bb \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework-plugin-netflix_%.bbappend \
|meta-rdk-comcast-video/recipes-extended/wpe-framework/wpeframework-plugin-netflix_git.bb \
|meta-rdk-comcast-video/recipes-extended/airplay/ \
|meta-rdk-comcast-video/recipes-extended/appmanager/ \
|meta-rdk-comcast-video/recipes-extended/asbluetoothrcu/ \
|meta-rdk-comcast-video/recipes-extended/audiocapturemgr/ \
|meta-rdk-comcast-video/recipes-extended/bzip2/ \
|meta-rdk-comcast-video/recipes-extended/closedcaption/ \
|meta-rdk-comcast-video/recipes-extended/cobalt/ \
|meta-rdk-comcast-video/recipes-extended/collectd/ \
|meta-rdk-comcast-video/recipes-extended/ctrlm/ \
|meta-rdk-comcast-video/recipes-extended/ctrlm-hal-rf4ce/ \
|meta-rdk-comcast-video/recipes-extended/devicesettings/ \
|meta-rdk-comcast-video/recipes-extended/diagnostics-snmp2json/ \
|meta-rdk-comcast-video/recipes-extended/dial/ \
|meta-rdk-comcast-video/recipes-extended/dtcpmgr/ \
|meta-rdk-comcast-video/recipes-extended/dvrmgr/ \
|meta-rdk-comcast-video/recipes-extended/fbdump-util/ \
|meta-rdk-comcast-video/recipes-extended/fdk-aac/ \
|meta-rdk-comcast-video/recipes-extended/firebolt-ripple/ \
|meta-rdk-comcast-video/recipes-extended/fog/ \
|meta-rdk-comcast-video/recipes-extended/fonts/ \
|meta-rdk-comcast-video/recipes-extended/gst-plugins-playersinkbin/ \
|meta-rdk-comcast-video/recipes-extended/halsnmp/ \
|meta-rdk-comcast-video/recipes-extended/hdmicec/ \
|meta-rdk-comcast-video/recipes-extended/hwselftest/ \
|meta-rdk-comcast-video/recipes-extended/iarmbus/ \
|meta-rdk-comcast-video/recipes-extended/iarmmgrs/ \
|meta-rdk-comcast-video/recipes-extended/injectedbundle/ \
|meta-rdk-comcast-video/recipes-extended/installrdk/ \
|meta-rdk-comcast-video/recipes-extended/ipcontrol/ \
|meta-rdk-comcast-video/recipes-extended/ledmgr/ \
|meta-rdk-comcast-video/recipes-extended/linuxconsoletools/ \
|meta-rdk-comcast-video/recipes-extended/lostandfound/ \
|meta-rdk-comcast-video/recipes-extended/malloc-zone/ \
|meta-rdk-comcast-video/recipes-extended/mauth-certs/ \
|meta-rdk-comcast-video/recipes-extended/mdns/ \
|meta-rdk-comcast-video/recipes-extended/mediaframework/ \
|meta-rdk-comcast-video/recipes-extended/mediastreamer/ \
|meta-rdk-comcast-video/recipes-extended/moca-hal/ \
|meta-rdk-comcast-video/recipes-extended/netflix/ \
|meta-rdk-comcast-video/recipes-extended/networkmgr/ \
|meta-rdk-comcast-video/recipes-extended/nrdplugin/ \
|meta-rdk-comcast-video/recipes-extended/nuanceeve/ \
|meta-rdk-comcast-video/recipes-extended/packagegroups/ \
|meta-rdk-comcast-video/recipes-extended/playready/ \
|meta-rdk-comcast-video/recipes-extended/playreadycdmi/ \
|meta-rdk-comcast-video/recipes-extended/playready-cdm-rdk/ \
|meta-rdk-comcast-video/recipes-extended/playready-cdm-rdk-netflix/ \
|meta-rdk-comcast-video/recipes-extended/podmgr/ \
|meta-rdk-comcast-video/recipes-extended/qrencode/ \
|meta-rdk-comcast-video/recipes-extended/rdkat/ \
|meta-rdk-comcast-video/recipes-extended/rdk-collectd-plugins/ \
|meta-rdk-comcast-video/recipes-extended/rdk-diagnostics/ \
|meta-rdk-comcast-video/recipes-extended/rdkmediaplayer/ \
|meta-rdk-comcast-video/recipes-extended/rdkx_logger/ \
|meta-rdk-comcast-video/recipes-extended/recorder/ \
|meta-rdk-comcast-video/recipes-extended/rtcast/ \
|meta-rdk-comcast-video/recipes-extended/runsnmp/ \
|meta-rdk-comcast-video/recipes-extended/sdvagent/ \
|meta-rdk-comcast-video/recipes-extended/secapi_netflix/ \
|meta-rdk-comcast-video/recipes-extended/sysint/ \
|meta-rdk-comcast-video/recipes-extended/sectionfilter/ \
|meta-rdk-comcast-video/recipes-extended/snmp/ \
|meta-rdk-comcast-video/recipes-extended/storagemanager/ \
|meta-rdk-comcast-video/recipes-extended/subtec/ \
|meta-rdk-comcast-video/recipes-extended/syeplayer/ \
|meta-rdk-comcast-video/recipes-extended/sys_mon_tools/ \
|meta-rdk-comcast-video/recipes-extended/tdk/ \
|meta-rdk-comcast-video/recipes-extended/tenablehdcp/ \
|meta-rdk-comcast-video/recipes-extended/test-scripts/ \
|meta-rdk-comcast-video/recipes-extended/thunderstartupservices/ \
|meta-rdk-comcast-video/recipes-extended/tr69profiles/ \
|meta-rdk-comcast-video/recipes-extended/trm/ \
|meta-rdk-comcast-video/recipes-extended/tvsettings/ \
|meta-rdk-comcast-video/recipes-extended/tzdata/ \
|meta-rdk-comcast-video/recipes-extended/vod-client/ \
|meta-rdk-comcast-video/recipes-extended/webkitbrowser-plugin/ \
|meta-rdk-comcast-video/recipes-extended/whoami-client/ \
|meta-rdk-comcast-video/recipes-extended/whoami-client-dri/ \
|meta-rdk-comcast-video/recipes-extended/widevinecdmi/ \
|meta-rdk-comcast-video/recipes-extended/wifi-hal/ \
|meta-rdk-comcast-video/recipes-extended/wpe-backend/ \
|meta-rdk-comcast-video/recipes-extended/wpe-backend-rdk/ \
|meta-rdk-comcast-video/recipes-extended/wpe-web-extensions/ \
|meta-rdk-comcast-video/recipes-extended/wpe-webkit/ \
|meta-rdk-comcast-video/recipes-extended/xdial/ \
|meta-rdk-comcast-video/recipes-extended/xraudio/ \
|meta-rdk-comcast-video/recipes-extended/xr-sm-engine/ \
|meta-rdk-comcast-video/recipes-extended/xr-speech-router/ \
|meta-rdk-comcast-video/recipes-extended/secclient/secauthn_git.bb \
|meta-rdk-comcast-video/recipes-extended/secclient/sec-client-rdk-common.inc \
|meta-rdk-comcast-video/recipes-extended/secclient/socprovapi_git.bb \
|meta-rdk-comcast-video/recipes-qt/aamp/ \
|meta-rdk-comcast-video/recipes-qt/ave/ \
|meta-rdk-comcast-video/recipes-qt/cef-eglfs/ \
|meta-rdk-comcast-video/recipes-qt/ppapi-plugins/ \
|meta-rdk-comcast-video/recipes-qt/qtbrowser/ \
|meta-rdk-comcast-video/recipes-qt/qtwebrtc/ \
|meta-rdk-comcast-video/recipes-qt/rdkcef-testapp/ \
|meta-rdk-comcast-video/recipes-qt/servicemanager/ \
|meta-rdk-comcast-video/recipes-qt/socprovisioning/ \
|meta-rdk-comcast-video/recipes-qt/xre2-plugin/ \
|meta-rdk-comcast-video/recipes-qt/xre-webkitbrowser-plugin/ \
|meta-rdk-comcast-video/recipes-qt/cachehelpers/ \
|meta-rdk-comcast-video/recipes-qt/netflix-plugin/ \
|meta-rdk-comcast-video/recipes-qt/qt5/ \
|meta-rdk-comcast-video/recipes-qt/qtwayland-override/ \
|meta-rdk-comcast-video/recipes-qt/rdkbrowser/ \
|meta-rdk-comcast-video/recipes-qt/rtcav/ \
|meta-rdk-comcast-video/recipes-qt/servicemanagerfunctionaltest/ \
|meta-rdk-comcast-video/recipes-qt/wayland-plugin/ \
|meta-rdk-comcast-video/recipes-qt/xre-receiver/ \
|meta-rdk-comcast-video/recipes-rpi/wpe-framework/rdkservices_git.bbappend \
|meta-rdk-comcast-video/recipes-rpi/wpe-framework/wpeframework*.bbappend  \
|meta-rdk-comcast-video/recipes-rpi/aamp/ \
|meta-rdk-comcast-video/recipes-rpi/conf/  \
|meta-rdk-comcast-video/recipes-rpi/devicesettings/ \
|meta-rdk-comcast-video/recipes-rpi/injectedbundle/ \
|meta-rdk-comcast-video/recipes-rpi/playready/ \
|meta-rdk-comcast-video/recipes-rpi/socprovisioning/ \
|meta-rdk-comcast-video/recipes-rpi/xre-receiver/ \
|meta-rdk-comcast-video/recipes-rpi/cpg/ \
|meta-rdk-comcast-video/recipes-rpi/lighttpd/ \
|meta-rdk-comcast-video/recipes-rpi/servicemanager/ \
|meta-rdk-comcast-video/recipes-rpi/widevinecdmi/ \
|meta-rdk-comcast-video/recipes-rpi/wpe-webkit/ \
|meta-rdk-comcast-video/recipes-common/ \
|meta-rdk-comcast-video/recipes-connectivity/ \
|meta-rdk-comcast-video/recipes-containers/ \
|meta-rdk-comcast-video/recipes-core/ \
|meta-rdk-comcast-video/recipes-graphics/ \
|meta-rdk-comcast-video/recipes-mac/ \
|meta-rdk-comcast-video/recipes-multimedia/ \
|meta-rdk-comcast-video/recipes-protocols/ \
|meta-rdk-comcast-video/recipes-support/ \
|meta-rdk-comcast-video/recipes-thirdparty/ \
','',d)}"
