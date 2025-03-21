FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"

SRC_URI_append = " file://0001-do-not-return-error-if-duplicate-registration.patch "
