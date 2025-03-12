do_compile_prepend () {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'WanFailOverSupportEnable', 'true', 'false', d)}; then
        sed -i '/<?define RBUS_BUILD_FLAG_ENABLE=True?>/d' "${S}/config/RdkCellularManager.xml"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'WanManagerUnificationEnable', 'true', 'false', d)}; then
        sed -i '/<?define WAN_MANAGER_UNIFICATION_ENABLED=True?>/d' "${S}/config/RdkCellularManager.xml"
    fi
    if ${@bb.utils.contains('DISTRO_FEATURES', 'WanFailOverSupportEnable', 'true', 'false', d)}; then
        (${PYTHON} ${STAGING_BINDIR_NATIVE}/dm_pack_code_gen.py ${S}/config/RdkCellularManager.xml ${S}/source/CellularManager/dm_pack_datamodel.c)
    fi
}
