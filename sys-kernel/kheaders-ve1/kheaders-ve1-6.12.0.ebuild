
EAPI=8

RPM_COMPRESS_TYPE="none"
inherit rpm

DESCRIPTION="Linux kernel UAPI headers for NEC Aurora Vector Engine (VE1)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/3.6.0/Source/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/3.6.0/Source/kheaders-ve1-${PV}-55.9.1_1.el10.src.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# Header-only package: nothing to strip, no foreign ELF
RESTRICT="strip"

VE_PREFIX="/opt/nec/ve"

src_configure() {
	econf --with-ve_prefix="${VE_PREFIX}"
}
