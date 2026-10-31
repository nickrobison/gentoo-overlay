
EAPI=8

inherit autotools git-r3

DESCRIPTION="VE Device Driver library"
HOMEPAGE="https://github.com/veos-sxarr-NEC/libved"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/${PN}.git"

LICENSE="GPL-2"
SLOT="0"

DEPEND="app-accel/vp-kmod
app-accel/ve_drv-kmod"
RDEPEND="${DEPEND}"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myconf=(
		--with-no-memcpy
	)

	econf "${myconf[@]}"
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${ED}" install
}
