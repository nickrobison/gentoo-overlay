EAPI=8

RPM_COMPRESS_TYPE="xz"
inherit rpm

DESCRIPTION="NEC MMM MSL script payload (NEC-signed .nec scripts ve_monitor runs)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/"
# Shares the MMM version directory (3.0.8) but carries its own 1.2.1
# package version; the payload is byte-identical on el8.8 and el8.10.
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/3.0.8/mmm-msl-${PV}-4.el8.x86_64.rpm"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

# Payload dirs are root:veadmin 0750; the rpm2targz cpio shim chokes on
# them as the build user, so force the rpm2archive path (same reason as
# app-accel/nec-mmm).
BDEPEND=">=app-arch/rpm-4.19.0[lzma(+)]"

# Vendor %pre runs `groupadd -r veadmin` because the payload is
# root:veadmin; the account comes as a dep instead (groupadd is banned
# in EAPI 8).
RDEPEND="acct-group/veadmin"

src_install() {
	[[ -f etc/opt/nec/ve/mmm/msl/throttling/mmm_throt_level.nec ]] ||
		die "unexpected rpm layout"

	insinto /etc/opt/nec/ve/mmm
	doins -r etc/opt/nec/ve/mmm/msl

	# Vendor layout: root:veadmin, dirs 0750, scripts 0640. ve_monitor
	# signature-checks every .nec file here; without this payload the
	# MMM-Daemon dies with "can not access mmm-config: file open(...)"
	# and then SIGABRTs.
	fowners -R root:veadmin /etc/opt/nec/ve/mmm/msl
	fperms 0750 /etc/opt/nec/ve/mmm/msl \
		/etc/opt/nec/ve/mmm/msl/errlog \
		/etc/opt/nec/ve/mmm/msl/init \
		/etc/opt/nec/ve/mmm/msl/param \
		/etc/opt/nec/ve/mmm/msl/sd \
		/etc/opt/nec/ve/mmm/msl/throttling
	# fperms prepends ${ED}, so shell globs would resolve against the
	# build host -- walk the tree instead.
	local f
	while IFS= read -r -d '' f; do
		fperms 0640 "${f#${ED}}"
	done < <(find "${ED}/etc/opt/nec/ve/mmm/msl" -type f -print0)
}
