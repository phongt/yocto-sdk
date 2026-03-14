EXTRA_OECONF:remove = "--disable-static"
EXTRA_OECONF += "--enable-static"

PACKAGES =+ "lib${BPN}-dev"

FILES:lib${BPN}-dev += " ${libdir}/*.a ${libdir}/*.so ${base_libdir}/*.a ${libdir}/${BPN}/*.a ${includedir}/*"

# Empty -staticdev to avoid duplicate file claim
FILES:lib${BPN}-staticdev = ""

# Suppress the staticdev QA warning since this is intentional
INSANE_SKIP:lib${BPN}-dev += "staticdev"
