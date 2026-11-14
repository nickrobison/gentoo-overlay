EAPI=8

RPM_COMPRESS_TYPE="xz"

inherit rpm

# The payload ships root-locked dirs (0770 var tree, setuid 4750 td/ft
# dir): the rpm2targz cpio shim chokes on them as the build user; force
# the tar-based rpm2archive path (same workaround as app-accel/nec-mmm).
BDEPEND=">=app-arch/rpm-4.19.0[lzma(+)]"

DESCRIPTION="NEC Vector Engine fault-test (FT) monitor and boot-error detection catalog"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/3.0.8/ftmon-${PV}-0.el8.x86_64.rpm"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror strip userpriv"

# ve_monitor spawns ftmon per the mmm .config (td_ft_exec) during
# boot-error detection. The binary NEEDs libsignature.so (nec-mmm
# payload, found via mmm-x86_64.conf) and libved.so.3; the result dir
# is group-rotated with veadmin (logrotate su line).
#
# The install-time "Unresolved soname dependencies: libsignature.so" QA
# notice is expected: the soname resolves at runtime through
# ld.so.conf.d/mmm-x86_64.conf (app-accel/nec-mmm), which the soname
# scanner does not follow.
RDEPEND="
	acct-group/veadmin
	app-accel/libved
	app-accel/nec-mmm
"

VE_PREFIX="/opt/nec/ve"

QA_PREBUILT="${VE_PREFIX}/td/ft/ftmon"

src_install() {
	local src="${WORKDIR}${VE_PREFIX}/td/ft"

	[[ -x ${src}/ftmon ]] || die "unexpected rpm layout"

	exeinto "${VE_PREFIX}/td/ft"
	doexe "${src}"/ftmon "${src}"/prepro.pl "${src}"/all_ft.py

	insinto /etc/logrotate.d
	doins "${WORKDIR}"/etc/logrotate.d/ft
	fperms 0644 /etc/logrotate.d/ft

	# The FT data tree ships executable (0750): the ft_list_* catalogs
	# and FTs/*.nec test scripts are consumed through ftmon, and the RPM
	# carries the exec bit on every one of them. Only the per-slot
	# int/interrupt.ve* seeds are 0640. Mirror both classes.
	insinto /var/opt/nec/ve/td/ft
	doins -r "${WORKDIR}"/var/opt/nec/ve/td/ft/{catalog,FTs,int}
	local f
	while IFS= read -r -d '' f; do
		fperms 0750 "${f#${ED%/}}"
	done < <(cd "${WORKDIR}" && find var/opt/nec/ve/td/ft/catalog var/opt/nec/ve/td/ft/FTs -type f -print0)
	while IFS= read -r -d '' f; do
		fperms 0640 "${f#${ED%/}}"
	done < <(cd "${WORKDIR}" && find var/opt/nec/ve/td/ft/int -type f -print0)

	# ftmon writes the per-slot FT result logs here; logrotate.d/ft
	# rotates them with `su root veadmin`.
	keepdir /var/opt/nec/ve/td/ft/result
}

pkg_postinst() {
	# Upstream ships result/ 0770 and rotates its logs as root:veadmin;
	# the RDEPEND above guarantees the group exists.
	chown root:veadmin "${EROOT}"/var/opt/nec/ve/td/ft/result ||
		ewarn "could not chown ${EROOT}/var/opt/nec/ve/td/ft/result"
	chmod 0770 "${EROOT}"/var/opt/nec/ve/td/ft/result ||
		ewarn "could not chmod ${EROOT}/var/opt/nec/ve/td/ft/result"
	elog "ve_monitor runs ${VE_PREFIX}/td/ft/ftmon for boot-error"
	elog "detection (mmm .config: td_ft_exec). Without this package the"
	elog "daemon logs 'FT File Open Failed' and latches the card UNAVAILABLE."
	elog "all_ft.py is a python2 payload helper shipped as-is (not wired"
	elog "into the boot path)."
}
