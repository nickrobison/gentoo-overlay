
EAPI=8

RPM_COMPRESS_TYPE=xz
inherit rpm

DESCRIPTION="NEC Aurora Compiler (ncc) Shared Libraries"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/fcc/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/fcc/${PV}/x86_64/nec-nc++-shared-${PV}-${PV}-1.x86_64.rpm"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# Vendor prebuilt binaries:
#  - foreign-arch (VE/VE3 ELF): portage strip + multilib checks can't handle
#  - libncc.so contains text relocations
# NOTE: QA_TEXTRELS paths are anchored relative to ${ED} (no leading slash).
QA_PREBUILT="/opt/nec/*"
QA_TEXTRELS="opt/nec/ve/* opt/nec/ve3/*"
RESTRICT="strip"

src_unpack() {
	default
	rpm_unpack nec-nc++-shared-5.4.1-5.4.1-1.x86_64.rpm
}

src_install() {
	dodir "/opt"
	mv "${S}/opt/nec" "${D}/opt" || die
}
