EAPI=8

RPM_COMPRESS_TYPE="xz"
inherit rpm

DESCRIPTION="NEC MMM hardware-spec YAML and ve_nodes host configuration data"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/"
# Shares the MMM version directory (3.0.8) but carries its own 1.2.1
# package version; the payload is byte-identical on el8.8 and el8.10.
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/3.0.8/mmm-config-${PV}-4.el8.x86_64.rpm"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

# Vendor payload dirs are root:veadmin 0750 (see app-accel/mmm-msl).
BDEPEND=">=app-arch/rpm-4.19.0[lzma(+)]"

# Vendor %pre creates veadmin (groupadd banned in EAPI 8, so a dep);
# the %post helper shells out to dmidecode to match the host against
# the shipped ve_nodes_json list.
RDEPEND="acct-group/veadmin sys-apps/dmidecode"

src_install() {
	[[ -f etc/opt/nec/ve/mmm/info/ve_hw_spec.yaml ]] ||
		die "unexpected rpm layout"

	# ve_hw_spec.yaml is what ve_monitor loads at daemon start; missing
	# it logs "MMM Yaml file change error" before the signature check.
	insinto /etc/opt/nec/ve/mmm
	doins -r etc/opt/nec/ve/mmm/analysis etc/opt/nec/ve/mmm/info
	insinto /etc/opt/nec/ve3/mmm
	doins -r etc/opt/nec/ve3/mmm/info

	exeinto /opt/nec/ve/mmm/analysis/sbin
	doexe opt/nec/ve/mmm/analysis/sbin/mmm-analysis-post.sh \
		opt/nec/ve/mmm/analysis/sbin/mmm-config-json.sh

	# Vendor layout: root:veadmin; data 0640, yaml 0644 (doins default),
	# dirs 0750, helpers 0750.
	fowners -R root:veadmin /etc/opt/nec/ve/mmm/analysis \
		/etc/opt/nec/ve/mmm/info /etc/opt/nec/ve3/mmm/info
	fperms 0750 /etc/opt/nec/ve/mmm/analysis/ve_nodes_json \
		/etc/opt/nec/ve/mmm/analysis/ve_nodes_json/ve3
	fperms 0750 /opt/nec/ve/mmm/analysis/sbin/mmm-analysis-post.sh \
		/opt/nec/ve/mmm/analysis/sbin/mmm-config-json.sh
	# fperms prepends ${ED}, so shell globs would resolve against the
	# build host -- walk the tree instead.
	local f
	while IFS= read -r -d '' f; do
		fperms 0640 "${f#${ED}}"
	done < <(find "${ED}/etc/opt/nec/ve/mmm/analysis" -type f -print0)
}

pkg_postinst() {
	# Vendor %post: match the host board against ve_nodes_json and
	# install /etc/opt/nec/ve/veos/ve_nodes.json. Irrelevant (and
	# skipped) for cross-root installs.
	if [[ ${EROOT} == / ]]; then
		/opt/nec/ve/mmm/analysis/sbin/mmm-config-json.sh 1 ||
			ewarn "mmm-config-json.sh did not install ve_nodes.json (host not in list)"
	fi
	elog "MMM hardware spec data installed (ve_hw_spec.yaml)."
}
