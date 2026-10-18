
EAPI=8

inherit autotools git-r3 linux-mod-r1

DESCRIPTION="NEC Aurora VE-DRV Kernel Module"
HOMEPAGE="https://github.com/veos-sxarr-NEC/ve_dev-kmod"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/ve_drv-kmod.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

VE_PREFIX="/opt/nec/ve/veos"

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	local myconf=(
#		--prefix="${EPREFIX}${VE_PREFIX}"
		--enable-static=no
#		--includedir="${EPREFIX}/usr/include"
	)

	econf "${myconf[@]}"
}

src_compile() {
	emake "${MODULES_MAKEARGS[@]}"
}

src_install() {
	emake "${MODULES_MAKEARGS[@]}" DESTDIR="${ED}" install
	modules_post_process

}

pkg_postinst() {
	linux-mod-r1_pkg_postinst
}
