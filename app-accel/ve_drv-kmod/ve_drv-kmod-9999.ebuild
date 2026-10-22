
EAPI=8

inherit autotools git-r3 linux-mod-r1

DESCRIPTION="NEC Aurora VE-DRV Kernel Module"
HOMEPAGE="https://github.com/veos-sxarr-NEC/ve_dev-kmod"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/ve_drv-kmod.git"

LICENSE="GPL-2"
SLOT="0"

DEPEND="app-accel/vp-kmod"
RDEPEND="${DEPEND}"

VE_PREFIX="/opt/nec/ve/veos"

PATCHES=(
	"${FILESDIR}"/0001-Makefile-am-Gentoo-port-build-fixes.patch
	"${FILESDIR}"/0002-main-c-const-dev_uevent-and-file-local-helpers.patch
	"${FILESDIR}"/0003-mmap-c-upstream-kernel-compat-instead-of-RHEL-macros.patch
	"${FILESDIR}"/0004-kmod-make-file-local-helpers-static-GCC16.patch
)

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myconf=(
		--prefix="${VE_PREFIX}"
		--includedir="${EPREFIX}/usr/include"
		--with-release-id=1
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
