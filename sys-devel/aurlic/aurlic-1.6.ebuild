
EAPI=8

RPM_COMPRESS_TYPE=xz
inherit rpm

DESCRIPTION="NEC Aurora Aurlic"
HOMEPAGE="https://github.com/veos-sxarr-NEC/ve_dev-kmod"
SRC_URI=""https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/aurlic/${PV}/x86_64/aurlic-lib-${PV}-1.x86_64.rpm
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

VE_PREFIX="/opt/nec/aur_license"
QA_PREBUILT="${VE_PREFIX}/*"

src_unpack() {
	default
	rpm_unpack aurlic-lib-${PV}-1.x86_64.rpm
}

src_install() {

	insinto "${DE}/usr/lib64"
	doins "${WORKDIR}/usr/lib64/"*

	dodir "/opt/nec"
	eval mv -i "${S}${VE_PREFIX}" "${D}/opt/nec" || die
}
