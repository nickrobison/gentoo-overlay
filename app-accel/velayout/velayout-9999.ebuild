
EAPI=8

inherit autotools git-r3

DESCRIPTION="log4c layout library for VEOS"
HOMEPAGE="https://github.com/veos-sxarr-NEC/velayout"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/velayout.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="dev-libs/log4c"
RDEPEND="${DEPEND}"
BDEPEND=""

VE_PREFIX="/opt/nec/ve/veos"

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

}
