
EAPI=8

inherit autotools git-r3

DESCRIPTION="log4c layout library for veos"
HOMEPAGE="https://github.com/veos-sxarr-nec/velayout"
EGIT_REPO_URI="https://github.com/veos-sxarr-nec/velayout.git"

LICENSE="LGPL-2.1"
SLOT="0"

DEPEND="dev-libs/log4c"
RDEPEND="${DEPEND}"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	default
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${ED}" install

	find "${ED}" -name '*.la' -delete || die
}
