EAPI=8

RPM_COMPRESS_TYPE="xz"
inherit rpm

DESCRIPTION="NEC SX-Aurora TSUBASA VE card firmware (SBus/SerDes images)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/"
# Same payload on el8.8 and el8.10 (md5-identical); 3.0.8 is the only
# directory that carries it.
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/3.0.8/ve-firmware-${PV}-1.el8.noarch.rpm"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

BDEPEND=">=app-arch/rpm-4.19.0[lzma(+)]"

src_install() {
	[[ -f lib/firmware/fw_ve_sbus_00.bin ]] || die "unexpected rpm layout"
	# Vendor ships the SBus/SerDes ROMs twice under both the generic
	# request_firmware() name (fw_ve_*) and the raw ROM name; the
	# driver probes either. 0644 root:root -- doins default matches.
	insinto /lib/firmware
	doins lib/firmware/*.bin
}
