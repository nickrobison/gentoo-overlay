EAPI=8

RPM_COMPRESS_TYPE="zstd"
inherit rpm

DESCRIPTION="VEOS public headers (sysve.h, veos_defs.h, vhcall.h, ...) for SX-Aurora TSUBASA"
HOMEPAGE="https://github.com/veos-sxarr-NEC/veos"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/${PV}/x86_64/${P}-1.el10.x86_64.rpm"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

VE_PREFIX="/opt/nec/ve"

# Headers only (ve + ve3 include trees): nothing to strip or soname-check.
# Build-time consumers: elf/dl-open.c in sys-libs/glibc-ve1 includes
# <sysve.h>/<veos_defs.h> under __ve__; NEC's glibc spec omits the
# BuildRequires because their build host had veos-headers installed.
src_unpack() {
	default
	rpm_unpack "${P}-1.el10.x86_64.rpm"
}

src_install() {
	[[ -d ${S}/opt ]] || die "unexpected rpm layout"
	mv "${S}/opt" "${ED}" || die
}
