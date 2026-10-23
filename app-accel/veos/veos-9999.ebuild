EAPI=8

inherit autotools git-r3

DESCRIPTION="NEC Aurora Vector Engine Operating System (VEOS)"
HOMEPAGE="https://github.com/veos-sxarr-NEC/veos"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/${PN}.git"

LICENSE="GPL-2"
SLOT="0"

# Mirrors veos.spec.in BuildRequires/Requires with Gentoo equivalents:
#   libved -> app-accel/libved, velayout -> app-accel/velayout,
#   protobuf-c + protobuf-compiler(protoc), log4c, systemd (libudev.h +
#   sd_notify() in src/ived), libuuid -> sys-apps/util-linux,
#   libcap -> sys-libs/libcap, libdhash -> dev-libs/ding-libs, procps-ng.
# ve-memory-mapping-devel (spec BuildRequires) is not packaged here (no
# open source/RPM access); veos falls back to its in-tree
# vemmagent_fallback.h -- full compile verified green without it.
# sys-libs/musl-ve intentionally NOT a dep: --with-ve-musl-includedir is
# only the install *destination* for veos's own bundled headers
# (include/Makefile.am: ve_musl_include_HEADERS, sources in-tree) and a
# value AC_SUBST'd into the debian packaging manifest. Re-add only if a
# build step starts reading files from that path.
DEPEND="app-accel/libved
	app-accel/velayout
	dev-libs/ding-libs
	dev-libs/log4c
	dev-libs/protobuf-c
	sys-apps/systemd
	sys-apps/util-linux
	sys-libs/libcap
	sys-process/procps"
RDEPEND="${DEPEND}"
# protoc build-only (lib/Makefile.am, lib/libveosprotoc); protoc-c itself
# ships with dev-libs/protobuf-c above, which is in DEPEND and therefore
# present at build time.
BDEPEND="dev-libs/protobuf"

src_prepare() {
	default
	eapply "${FILESDIR}"/veos-configure-libproc2.patch \
		"${FILESDIR}"/veos-termios-include.patch \
		"${FILESDIR}"/veos-pids-val.patch
	eautoreconf
}

src_configure() {
	local myconf=(
		# Destinations only. Defaults for ve-/ve3-includedir already
		# land on /opt/nec/ve{,3}/include (ve_prefix=/opt/nec/ve), so
		# veos takes over the ten headers the standalone
		# dev-libs/veos-headers package used to ship; that ebuild is
		# gone and glibc-ve1/libsysve now BDEPEND on this package.
		--with-ve-musl-includedir=/opt/nec/ve/musl/include
		# Where ve-memory-mapping-devel would install the VEMM agent
		# header; the dir does not exist on this host and the in-tree
		# fallback header covers it.
		--with-vemm-agent-includedir=/opt/nec/ve/veos/include
	)

	econf "${myconf[@]}"
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${ED}" install
}
