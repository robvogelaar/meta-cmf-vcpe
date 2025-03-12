do_compile_prepend () {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'vendor_class_id_feature', 'true', 'false', d)}; then
        sed -i '/<?define VENDOR_CLASS_ID=True?>/d' "${S}/config/LMLite.XML"
    fi
}
