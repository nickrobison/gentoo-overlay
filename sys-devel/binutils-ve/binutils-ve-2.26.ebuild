
EAPI=8

RPM_COMPRESS_TYPE=xz
inherit rpm

DESCRIPTION="NEC Aurora Binutils (VE)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/binutils/${PV}-2.12/x86_64/binutils-ve-${PV}-2.12.x86_64.rpm"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

VE_PREFIX="/opt/nec/ve"
QA_PREBUILT="${VE_PREFIX}/*"

src_unpack() {
	default
	rpm_unpack binutils-ve-2.26-2.12.x86_64.rpm
}

src_install() {
	dodir "/opt/nec"
	eval mv -i "${S}${VE_PREFIX}" "${D}/opt/nec" || die
}
