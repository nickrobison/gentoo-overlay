EAPI=8

inherit autotools git-r3

DESCRIPTION="VE OS information library (libveosinfo) for the VEOS stack"
HOMEPAGE="https://github.com/veos-sxarr-NEC/veosinfo_source"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/veosinfo_source.git"

LICENSE="LGPL-2.1"
SLOT="0"

# configure.ac AC_CHECK_LIB chain: udev, yaml, protobuf-c, log4c,
# velayout. libveosinfo_la_LIBADD = -lveproductinfo comes from veos
# (same /opt/nec/ve/veos/lib64 dir this package links into, see
# --libdir below). protoc-c (dev-libs/protobuf-c) runs at configure
# time via AC_CONFIG_COMMANDS for veos_RPM.proto.
DEPEND="app-accel/velayout
	app-accel/veos
	dev-libs/libyaml
	dev-libs/log4c
	dev-libs/protobuf-c
	virtual/libudev"
RDEPEND="${DEPEND}"
BDEPEND+="dev-libs/protobuf-c"

src_prepare() {
	default
	# ACLOCAL_AMFLAGS = -I m4 but the git tree ships no m4/ dir;
	# aclocal dies without it.
	mkdir -p "${S}/m4" || die
	eautoreconf
}

src_configure() {
	# configure.ac only adds -L${prefix}/lib{,64} (=/usr/...), but
	# -lveproductinfo (LIBADD) lives with the veos libs.
	local -x LDFLAGS="-L/opt/nec/ve/veos/lib64 ${LDFLAGS}"

	local myconf=(
		# Spec/vendor layout: libveosinfo.so* sits beside the veos libs
		# in /opt/nec/ve/veos/lib64 (ld.so.conf.d/veos.conf covers it).
		# econf's default --libdir=/usr/lib64 must lose -> append LAST.
		# Headers keep prefix=/usr -> /usr/include/veosinfo/, which is
		# what veoffload's #include <veosinfo/veosinfo.h> expects from
		# the default search path.
		--libdir=/opt/nec/ve/veos/lib64
	)

	econf "${myconf[@]}"
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${ED}" install

	# Same cleanup as the veos spec %install: no static/libtool
	# archives in the libdir.
	rm -f "${ED}"/opt/nec/ve/veos/lib64/lib*.a \
		"${ED}"/opt/nec/ve/veos/lib64/lib*.la
}
