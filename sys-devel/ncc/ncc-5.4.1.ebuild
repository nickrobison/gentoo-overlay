
EAPI=8

RPM_COMPRESS_TYPE=xz
inherit rpm

DESCRIPTION="NEC Aurora Compiler"
HOMEPAGE="https://github.com/veos-sxarr-NEC/ve_dev-kmod"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/fcc/${PV}/x86_64/nec-nc++-${PV}-${PV}-1.x86_64.rpm"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="sys-devel/binutils-ve
sys-devel/aurlic
"
RDEPEND="${DEPEND} sys-devel/nec-shared"
BDEPEND=""

VE_PREFIX="/opt/nec/ve"
QA_PREBUILT="${VE_PREFIX}/*"

src_unpack() {
	default
	rpm_unpack nec-nc++-5.4.1-5.4.1-1.x86_64.rpm
}

src_install() {
	dodir "/opt/nec"
	eval mv -i "${S}${VE_PREFIX}" "${D}/opt/nec" || die

	dodir "/opt/nec/ve/libexec"
	dosym -r "${VE_PREFIX}/ncc/${PV}/libexec/ccom" "${VE_PREFIX}/libexec/ccom"
	dosym -r "${VE_PREFIX}/bin/nc++-${PV}" "${VE_PREFIX}/bin/nc++"
	dosym -r "${VE_PREFIX}/bin/ncc-${PV}" "${VE_PREFIX}/bin/ncc"

}
