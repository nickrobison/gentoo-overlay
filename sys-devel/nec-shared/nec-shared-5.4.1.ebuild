
EAPI=8

RPM_COMPRESS_TYPE=xz
inherit rpm

DESCRIPTION="NEC Aurora Compiler Shared Libraries"
HOMEPAGE="https://github.com/veos-sxarr-NEC/ve_dev-kmod"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/fcc/${PV}/x86_64/nec-nc++-shared-${PV}-${PV}-1.x86_64.rpm"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

VE_PREFIX="/opt/nec"
QA_PREBUILT="${VE_PREFIX}/*"

src_unpack() {
	default
	rpm_unpack nec-nc++-shared-5.4.1-5.4.1-1.x86_64.rpm
}

src_install() {
	dodir "/opt"
	eval mv -i "${S}${VE_PREFIX}" "${D}/opt" || die
}
