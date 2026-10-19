
EAPI=8

inherit autotools git-r3

description="log4c layout library for veos"
homepage="https://github.com/veos-sxarr-nec/velayout"
egit_repo_uri="https://github.com/veos-sxarr-nec/velayout.git"

license="gpl-2"
slot="0"
keywords="~amd64"

depend="dev-libs/log4c"
rdepend="${depend}"
bdepend=""

ve_prefix="/opt/nec/ve/veos"

src_prepare() {
	default
}

src_configure() {
	default
}

src_compile() {
	emake
}

src_install() {
	emake destdir="${ed}" install
}
