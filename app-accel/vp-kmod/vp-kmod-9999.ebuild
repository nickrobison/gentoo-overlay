
EAPI=8

inherit autotools git-r3 linux-mod-r1

DESCRIPTION="NEC Aurora VP Kernel Module"
HOMEPAGE="https://github.com/veos-sxarr-NEC/vp-kmod"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/vp-kmod.git"

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
		--prefix="${VE_PREFIX}"
		--includedir="${EPREFIX}/usr/include"
		# Upstream turns this into MODULE_INFO(release) as "_<id>" and the
		# module load banner. Its own mkrpm.sh uses a build timestamp; for a
		# live ebuild the commit is deterministic and more useful.
		--with-release-id="${EGIT_VERSION:0:8}"
		# configure.ac defaults KERNEL to `uname -r`, which can differ from
		# the kernel being emerged for (e.g. @module-rebuild across a kernel
		# upgrade). That derails both KERNEL_SRC and KERNEL_MOD, and then
		# modules_post_process finds nothing under ${ED}/lib/modules/${KV_FULL}.
		--with-kernel="${KV_FULL}"
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
