EAPI=8

# MPFR 3.1.x compatibility library (libmpfr.so.4) for prebuilt NEC
# gcc-ve: its cc1/cc1plus/lto1 were linked on el8 against mpfr-3.1.6
# (libmpfr.so.4), while Gentoo's sys-libs/mpfr is 4.x (libmpfr.so.6).
# Header-less on purpose: only the versioned + unversioned libs are
# installed, so it cannot collide with sys-libs/mpfr.

DESCRIPTION="MPFR 3.1 shared library providing libmpfr.so.4"
HOMEPAGE="https://www.mpfr.org/"
SRC_URI="https://ftp.gnu.org/gnu/mpfr/mpfr-${PV}.tar.xz"
S="${WORKDIR}/mpfr-${PV}"

LICENSE="LGPL-3"
SLOT="0/4"
KEYWORDS="~amd64"

src_configure() {
	# --libdir matters: must land in /usr/lib64 (default ld search path)
	local myeconfargs=(
		--libdir="${EPREFIX}/usr/lib64"
		--disable-static
		--enable-shared
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default
	# Drop everything but the versioned runtime lib: headers/man/info/
	# .la belong elsewhere, and the unversioned libmpfr.so collides with
	# dev-libs/mpfr (nothing links against the compat copy anyway).
	rm -rf "${ED}"/usr/{include,share} \
		"${ED}"/usr/$(get_libdir)/libmpfr.so \
		"${ED}"/usr/$(get_libdir)/*.la || die
}
