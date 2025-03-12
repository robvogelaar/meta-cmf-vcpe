do_compile_prepend () {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'no_moca_support', 'true', 'false', d)}; then
        sed -i '/<?define NO_MOCA_FEATURE_SUPPORT=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'interworking', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_SUPPORT_INTERWORKING=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'dslite', 'true', 'false', d)}; then
        sed -i '/<?define DSLITE_FEATURE_SUPPORT=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'passpoint', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_SUPPORT_PASSPOINT=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'offchannel_scan_5g', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_OFF_CHANNEL_SCAN_5G=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'fwupgrade_manager', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_FWUPGRADE_MANAGER=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'rdkb_xdsl_ppp_manager', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_RDKB_XDSL_PPP_MANAGER=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'rdkb_wan_manager', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_RDKB_WAN_MANAGER=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'RadiusGreyList', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_SUPPORT_RADIUSGREYLIST=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'wifimotion', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_COGNITIVE_WIFIMOTION=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    sed -i '/<?define CONFIG_INTERNET2P0=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    sed -i '/<?define CONFIG_VENDOR_CUSTOMER_COMCAST=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    sed -i '/<?define CONFIG_CISCO_HOTSPOT=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    if ${@bb.utils.contains('DISTRO_FEATURES', 'bci', 'true', 'false', d)}; then
        sed -i '/<?define BCI=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
        sed -i '/<?define COSA_FOR_BCI=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
        sed -i '/<?define CONFIG_CISCO_TRUE_STATIC_IP=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
        sed -i '/<?define CONFIG_CISCO_FILE_TRANSFER=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    else
        sed -i '/<?define FEATURE_SUPPORT_ONBOARD_LOGGING=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
        sed -i '/<?define MOCA_HOME_ISOLATION=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
        
        if ${@bb.utils.contains('DISTRO_FEATURES', 'ddns_broadband', 'true', 'false', d)}; then
            sed -i '/<?define DDNS_BROADBANDFORUM=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
        fi
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'custom_ula', 'true', 'false', d)}; then
        sed -i '/<?define CUSTOM_ULA=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'ManagedWiFiSupportEnable', 'true', 'false', d)}; then
        sed -i '/<?define WIFI_MANAGE_SUPPORTED=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'dhcp_manager', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_RDKB_DHCP_MANAGER=True?>/d' "${S}/config-arm/TR181-USGv2.XML"
    fi
}
