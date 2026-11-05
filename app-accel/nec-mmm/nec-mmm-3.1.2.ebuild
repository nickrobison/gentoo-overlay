EAPI=8

RPM_COMPRESS_TYPE="xz"

inherit rpm systemd

# mmm payload has root-locked config dirs: the rpm2targz cpio shim chokes on
# them as the build user; force the tar-based rpm2archive path instead.
BDEPEND=">=app-arch/rpm-4.19.0[lzma(+)]"

DESCRIPTION="NEC Vector Engine Monitoring and Maintenance Manager (vecmd)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/${PV}/mmm-${PV}-0.el8.x86_64.rpm"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror strip userpriv"

RDEPEND="
	app-accel/libved
	dev-libs/libyaml
	dev-libs/openssl-compat:1.1.1
	x11-libs/libpciaccess
	virtual/libudev
	virtual/zlib
"

VE_PREFIX="/opt/nec/ve"

QA_PREBUILT="
	${VE_PREFIX}/mmm/bin/vecmd
	${VE_PREFIX}/mmm/sbin/ve_init
	${VE_PREFIX}/mmm/sbin/ve_monitor
	${VE_PREFIX}/sbin/ve_monitor
	${VE_PREFIX}/sbin/ve-off
	/opt/nec/ve3/mmm/sbin/ve_detect
	/opt/nec/ve3/mmm/sbin/ib_detect
	${VE_PREFIX}/mmm/lib64/libsignature.so
"

src_install() {
	local src="${WORKDIR}${VE_PREFIX}"
	local src3="${WORKDIR}/opt/nec/ve3"

	[[ -x ${src}/mmm/bin/vecmd ]] || die "unexpected rpm layout"

	exeinto "${VE_PREFIX}/mmm/bin"
	doexe "${src}"/mmm/bin/vecmd

	# PATH entry: /opt/nec/ve/bin is on PATH, and the VE1 vecmd is the
	# only one usable here -- the payload's /opt/nec/ve3/mmm/bin/vecmd is
	# the Aurora3 build (hardcodes /opt/nec/ve3/{etc,var}/... state that
	# this package does not ship). Point any vecmd lookup at the VE1
	# binary instead of the ve3 one.
	dosym ../mmm/bin/vecmd "${VE_PREFIX}/bin/vecmd"

	exeinto "${VE_PREFIX}/mmm/sbin"
	doexe "${src}"/mmm/sbin/ve_init
	doexe "${src}"/mmm/sbin/ve_monitor

	exeinto "${VE_PREFIX}/sbin"
	doexe "${src}"/sbin/ve_monitor
	doexe "${src}"/sbin/mmm-logrotate
	# ve-power.service execs ve-off from here
	doexe "${src}"/mmm/bin/ve-off

	fperms 0700 "${VE_PREFIX}/mmm/sbin/ve_monitor" "${VE_PREFIX}/sbin/ve_monitor"

	# fan control (nec-ve-fan-ctl.service + -mon)
	exeinto "${VE_PREFIX}/mmm/fan-ctl/sbin"
	doexe "${src}"/mmm/fan-ctl/sbin/nec-ve-fan-ctl{,-mon,-env-gen}.sh
	doexe "${src}"/mmm/fan-ctl/sbin/MAX.pl
	doexe "${src}"/mmm/fan-ctl/sbin/INFO

	# per-slot setpci helpers (31-series)
	exeinto "${VE_PREFIX}/mmm/pci"
	doexe "${src}"/mmm/pci/*.sh

	# canonical payload path: both the shipped mmm-x86_64.conf and
	# ve_monitor.env's LD_LIBRARY_PATH point at ${VE_PREFIX}/mmm/lib64
	# (the RPM never had it under /usr/lib64)
	exeinto "${VE_PREFIX}/mmm/lib64"
	doexe "${src}"/mmm/lib64/libsignature.so

	insinto /etc/opt/nec/ve
	doins -r "${WORKDIR}"/etc/opt/nec/ve/mmm
	fperms 0600 /etc/opt/nec/ve/mmm/ve_monitor.env
	insinto /etc/ld.so.conf.d
	doins "${WORKDIR}"/etc/ld.so.conf.d/mmm-x86_64.conf

	# The udev-triggered reconnect/setpci units exec out of the ve3 support
	# tree; install exactly the pieces those units and scripts reference.
	exeinto /opt/nec/ve3/mmm/sbin
	doexe "${src3}"/mmm/sbin/reconnect_ve "${src3}"/mmm/sbin/ve_detect "${src3}"/mmm/sbin/ib_detect
	exeinto /opt/nec/ve3/mmm/pci
	doexe "${src3}"/mmm/pci/*.sh
	insinto /etc/opt/nec/ve3
	doins -r "${WORKDIR}"/etc/opt/nec/ve3/mmm

	insinto /usr/lib/udev/rules.d
	doins "${WORKDIR}"/usr/lib/udev/rules.d/96-reconnect-ve.rules \
		"${WORKDIR}"/usr/lib/udev/rules.d/96-ve-ib-pci.rules

	systemd_dounit "${WORKDIR}"/usr/lib/systemd/system/{mmm,reconnect_ve@,setpci_ve@,setpci_ib@,setpci_vfio@,ve-power,nec-ve-fan-ctl,nec-ve-fan-ctl-mon}.service

	# Runtime state the launcher/vecmd/monitor all stat or write: the
	# real monitor logs into log/ and td/ (the upstream %post hands them
	# to veadmin), VE1 vecmd picks its daemon up from
	# /var/opt/nec/ve/mmm/<slot>/ve_monitor.pid + .udev_socket<n>, and
	# the shipped ve3 helpers use the ve3 twins. Without the tree vecmd
	# reports that it cannot find ve_monitor.
	keepdir /var/opt/nec/ve/mmm/{fan-ctl,log,td}
	keepdir /var/opt/nec/ve3/mmm/{.tmp,log/info,td}
}

# Deliberately NOT mirrored from the upstream RPM %post:
# - groupadd veadmin + root:veadmin 770 on {log,td}: groupadd is banned
#   in EAPI 8 (and an acct-group package would be a new package for a
#   group only the vendor installer needs); the monitor runs as root
#   from mmm.service, so plain root-owned dirs behave the same.
# - systemctl enable/start mmm: Gentoo installs units disabled, see elog.
# - ldconfig: portage runs it on merge (see app-accel/veos), and the
#   path it must pick up (/opt/nec/ve/mmm/lib64) is in the shipped
#   mmm-x86_64.conf.
pkg_postinst() {
	elog "MMM's ve_monitor daemon must be running for vecmd to query the card:"
	elog "  systemctl enable --now mmm"
	elog "Fan control on real cards:"
	elog "  systemctl enable --now nec-ve-fan-ctl nec-ve-fan-ctl-mon"
	elog "Card (re)connect and setpci helpers trigger via the installed udev rules."
	elog "Then, for example:"
	elog "  ${VE_PREFIX}/mmm/bin/vecmd state get"
	elog "  ${VE_PREFIX}/mmm/bin/vecmd info"
}
