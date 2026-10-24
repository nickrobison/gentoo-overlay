
EAPI=8

inherit autotools

DESCRIPTION="VEOS log4c libraries"
HOMEPAGE="https://github.com/veos-sxarr-NEC/log4c"
SRC_URI="https://github.com/veos-sxarr-NEC/${PN}/archive/refs/tags/veos_v${PV}.tar.gz"
S="${WORKDIR}/${PN}-veos_v${PV}"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

src_configure() {
	local myconf=(
		--prefix="${EPREFIX}/usr"
	)

	econf "${myconf[@]}"
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${ED}" install

}
