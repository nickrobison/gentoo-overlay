EAPI=8

RPM_COMPRESS_TYPE="zstd"

inherit rpm systemd

DESCRIPTION="NEC Vector Engine Monitoring and Maintenance Manager (vecmd)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/mmm/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/mmm/mmm-${PV}-0.el10.x86_64.rpm"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror strip"

BDEPEND="app-arch/rpm[zstd(+)]"

RDEPEND="
	app-accel/libved
	dev-libs/libyaml
	dev-libs/openssl:=
	virtual/zlib
	virtual/libudev
	x11-libs/libpciaccess
"

VE_PREFIX="/opt/nec/ve"

QA_PREBUILT="
	${VE_PREFIX}/mmm/bin/vecmd
	${VE_PREFIX}/mmm/sbin/ve_monitor
	${VE_PREFIX}/sbin/ve_monitor
	usr/lib64/libsignature.so
"

src_install() {
	local src="${WORKDIR}${VE_PREFIX}"

	[[ -x ${src}/mmm/bin/vecmd ]] || die "unexpected rpm layout"

	exeinto "${VE_PREFIX}/mmm/bin"
	doexe "${src}"/mmm/bin/vecmd

	exeinto "${VE_PREFIX}/mmm/sbin"
	doexe "${src}"/mmm/sbin/ve_monitor

	exeinto "${VE_PREFIX}/sbin"
	doexe "${src}"/sbin/ve_monitor

	fperms 0700 "${VE_PREFIX}/mmm/sbin/ve_monitor" "${VE_PREFIX}/sbin/ve_monitor"

	exeinto /usr/lib64
	doexe "${src}"/mmm/lib64/libsignature.so

	insinto /etc/opt/nec/ve
	doins -r "${WORKDIR}"/etc/opt/nec/ve/mmm
	fperms 0600 /etc/opt/nec/ve/mmm/ve_monitor.env

	systemd_dounit "${WORKDIR}"/usr/lib/systemd/system/mmm.service

	keepdir /var/opt/nec/ve/mmm
}

pkg_postinst() {
	elog "MMM's ve_monitor daemon must be running for vecmd to query the card:"
	elog "  systemctl enable --now mmm"
	elog "Then, for example:"
	elog "  ${VE_PREFIX}/mmm/bin/vecmd state get"
	elog "  ${VE_PREFIX}/mmm/bin/vecmd info"
}
