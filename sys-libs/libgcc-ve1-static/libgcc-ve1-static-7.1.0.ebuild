EAPI=8

RPM_COMPRESS_TYPE="zstd"
inherit rpm

DESCRIPTION="Static libgcc for the SX-Aurora TSUBASA Vector Engine (VE1)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/3.6.0/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/3.6.0/x86_64/${P}-10.el10.x86_64.rpm"
S="${WORKDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

VE_PREFIX="/opt/nec/ve"

# Static VE archive (libgcc.a) + docs; no host strip/soname QA applies.
RESTRICT="strip"
QA_PREBUILT="${VE_PREFIX}/*"

# Split out of the gcc-ve rpm upstream (Requires: libgcc-ve-static);
# the gcc driver resolves -lgcc via lib/gcc/ve-nec-linux-gnu/7.1.0/.
src_unpack() {
	default
	rpm_unpack "${P}-10.el10.x86_64.rpm"
}

src_install() {
	[[ -d ${S}/opt ]] || die "unexpected rpm layout"
	mv "${S}/opt" "${ED}" || die
}
