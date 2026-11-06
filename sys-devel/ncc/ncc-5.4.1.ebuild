
EAPI=8

RPM_COMPRESS_TYPE=xz
inherit rpm

DESCRIPTION="NEC Aurora Compiler"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/fcc/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/fcc/${PV}/x86_64/nec-nc++-${PV}-${PV}-1.x86_64.rpm"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="sys-devel/binutils-ve
sys-devel/aurlic
"
# ncc's driver hard-wires -lveproginf -lveperfcnt -lncc -lsysve into every
# link (see `ncc -v`), so the packages owning those objects must come in
# with the driver itself: without them nld reports
#   /opt/nec/ve/bin/nld: cannot find -lveproginf
#   /opt/nec/ve/bin/nld: cannot find -lveperfcnt
#   /opt/nec/ve/bin/nld: cannot find -lsysve
RDEPEND="${DEPEND}
	sys-devel/ncc-shared
	dev-libs/nec-veperf-ve1
	dev-libs/libsysve"

VE_PREFIX="/opt/nec/ve"
RESTRICT="strip"
QA_PREBUILT="${VE_PREFIX}/*"
QA_TEXTRELS="opt/nec/ve/*"

src_unpack() {
	default
	rpm_unpack nec-nc++-5.4.1-5.4.1-1.x86_64.rpm
}

src_install() {
	dodir /opt/nec
	mv -i "${S}${VE_PREFIX}" "${ED}/opt/nec" || die

	dodir /opt/nec/ve/libexec
	dosym -r "${VE_PREFIX}/ncc/${PV}/libexec/ccom" "${VE_PREFIX}/libexec/ccom"
	dosym -r "${VE_PREFIX}/bin/nc++-${PV}" "${VE_PREFIX}/bin/nc++"
	dosym -r "${VE_PREFIX}/bin/ncc-${PV}" "${VE_PREFIX}/bin/ncc"

}
