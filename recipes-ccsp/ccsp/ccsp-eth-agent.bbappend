do_compile_prepend () {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'rdkb_wan_manager', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_RDKB_WAN_MANAGER=True?>/d' "${S}/config/TR181-EthAgent.xml"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'rdkb_wan_upstream', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_RDKB_WAN_UPSTREAM=True?>/d' "${S}/config/TR181-EthAgent.xml"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'rdkb_auto_port_switch', 'true', 'false', d)}; then
        sed -i '/<?define FEATURE_RDKB_AUTO_PORT_SWITCH=True?>/d' "${S}/config/TR181-EthAgent.xml"
    fi
    (${PYTHON} ${STAGING_BINDIR_NATIVE}/dm_pack_code_gen.py ${S}/config/TR181-EthAgent.xml ${S}/source/EthSsp/dm_pack_datamodel.c)
}
