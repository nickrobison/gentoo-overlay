EAPI=8

RPM_COMPRESS_TYPE="xz"
inherit rpm

# Prebuilt RPM bootstrap compiler, renamed from sys-devel/gcc-ve so the
# source rebuild (sys-devel/gcc-ve, git-r3 from veos-sxarr-NEC/gcc-ve)
# can land under the canonical name without breaking dependents.

DESCRIPTION="GCC 7.1.0 port for the SX-Aurora TSUBASA Vector Engine (prebuilt)"
HOMEPAGE="https://github.com/veos-sxarr-NEC/gcc-ve"
# ${P} is gcc-ve-bin-* now; the upstream artifact keeps its gcc-ve name.
SRC_URI="https://github.com/veos-sxarr-NEC/gcc-ve/releases/download/gcc-ve-${PV}-7/gcc-ve-${PV}-7.el8.x86_64.rpm"
S="${WORKDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

VE_PREFIX="/opt/nec/ve"

# x86_64 driver/cc1 plus VE target objects (crt*, libgcov); host
# strip/soname QA would choke on the VE ELF.
RESTRICT="strip"
QA_PREBUILT="${VE_PREFIX}/*"

# nas/nld paths are baked into the driver (--with-as/--with-ld) from
# binutils-ve; libgcc.a ships in libgcc-ve1-static; cc1 et al need
# libmpfr.so.4 from mpfr-compat (el8-era MPFR). A VE libc (prebuilt
# sys-libs/glibc-ve1 for bootstrap, or source-built sys-libs/glibc-ve1
# -r1) is needed to link, but is deliberately not a hard RDEPEND so
# libc choice stays open.
DEPEND="sys-devel/binutils-ve
	sys-libs/libgcc-ve1-static
	sys-libs/mpfr-compat"
RDEPEND="${DEPEND}"

	src_unpack() {
		default
		rpm_unpack "gcc-ve-${PV}-7.el8.x86_64.rpm"
	}

src_install() {
	# Payload: opt/nec/ve/{bin,lib,libexec,include/c++,share,...}.
	# usr/ holds only RPM build-id links and etc/ is empty: both dropped.
	[[ -d ${S}/opt ]] || die "unexpected rpm layout"
	mv "${S}/opt" "${ED}" || die
}
