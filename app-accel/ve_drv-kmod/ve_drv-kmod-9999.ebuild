
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
		# Upstream turns this into MODULE_INFO(release) as "_<id>" and the
		# module load banner. Its own mkrpm.sh uses a build timestamp; for a
		# live ebuild the commit is deterministic and more useful.
		--with-release-id="${EGIT_VERSION:0:8}"
		# configure.ac defaults KERNEL to `uname -r`, which can differ from
		# the kernel being emerged for (e.g. @module-rebuild across a kernel
		# upgrade). That derails both KERNEL_SRC and KERNEL_MOD, and then
		# modules_post_process finds nothing under ${ED}/lib/modules/${KV_FULL}.
		--with-kernel="${KV_FULL}"
		# configure.ac defaults SYSTEMD_UNITDIR to ${prefix}/lib/systemd/system,
		# which with our prefix lands in /opt and is invisible to systemd.
		# Upstream's RPM passes %{_unitdir} the same way.
		--with-systemd-unitdir="${EPREFIX}/usr/lib/systemd/system"
	)

	econf "${myconf[@]}"
}

src_compile() {
	# Upstream Makefile hardcodes KERNEL_SRC=/lib/modules/$KERNEL/build, which
	# only exists once the kernel's modules are installed. linux-mod-r1 has
	# already resolved the actual (possibly split) build tree as KV_OUT_DIR and
	# verified its Module.symvers, so build against that instead.
	emake "${MODULES_MAKEARGS[@]}" KERNEL_SRC="${KV_OUT_DIR}"
}

src_install() {
	emake "${MODULES_MAKEARGS[@]}" KERNEL_SRC="${KV_OUT_DIR}" \
		DESTDIR="${ED}" install
	modules_post_process
}

pkg_postinst() {
	linux-mod-r1_pkg_postinst
}
