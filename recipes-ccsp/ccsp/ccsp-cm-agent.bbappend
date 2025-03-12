do_compile_prepend () {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'highsplit', 'true', 'false', d)}; then
        sed -i '/<?define \*CM\*HIGHSPLIT_SUPPORTED_=True?>/d' "${S}/config-arm/TR181-CM.XML"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'rdkb_wan_manager', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_RDKB_WAN_MANAGER=True?>/d' "${S}/config-arm/TR181-CM.XML"
    fi
}