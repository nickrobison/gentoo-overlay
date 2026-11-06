EAPI=8

RPM_COMPRESS_TYPE="xz"
inherit rpm

DESCRIPTION="NEC SX-Aurora TSUBASA VMC firmware image (aurora_MK10.bin)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/"
# Same payload on el8.8 and el8.10 (md5-identical); 3.0.8 is the only
# directory that carries it.
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/3.0.8/vmcfw-${PV}-2.el8.noarch.rpm"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

BDEPEND=">=app-arch/rpm-4.19.0[lzma(+)]"

src_install() {
	[[ -f etc/opt/nec/ve/mmm/vmc/aurora_MK10.bin ]] ||
		die "unexpected rpm layout"
	# ve_monitor's "VE0 1st Init" sequence flashes this image to the
	# VMC; without it the MMM-Daemon SIGABRTs during initialization.
	insinto /etc/opt/nec/ve/mmm
	doins -r etc/opt/nec/ve/mmm/vmc
}
