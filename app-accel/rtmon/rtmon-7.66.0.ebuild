EAPI=8

RPM_COMPRESS_TYPE="xz"

inherit rpm

# The payload ships root-locked dirs (0770 var tree, setuid 4750 td/rt
# dir): the rpm2targz cpio shim chokes on them as the build user; force
# the tar-based rpm2archive path (same workaround as app-accel/nec-mmm).
BDEPEND="dev-util/patchelf >=app-arch/rpm-4.19.0[lzma(+)]"

DESCRIPTION="NEC Vector Engine runtime-test (RT) monitor and catalog"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el8.10/mmm/3.0.8/rtmon-${PV}-2.el8.x86_64.rpm"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror strip userpriv"

# ve_monitor spawns rtmon per the mmm .config (td_rt_exec) for runtime
# tests. The binary NEEDs libsignature.so (nec-mmm payload, found via
# mmm-x86_64.conf) and libved.so.3; the result dir is group-rotated
# with veadmin (logrotate su line).
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

QA_PREBUILT="${VE_PREFIX}/td/rt/rtmon"

src_install() {
	local src="${WORKDIR}${VE_PREFIX}/td/rt"

	[[ -x ${src}/rtmon ]] || die "unexpected rpm layout"

	exeinto "${VE_PREFIX}/td/rt"
	doexe "${src}"/rtmon

	# Upstream embeds a DT_RPATH whose first component is a relative
	# build-machine path ('../AUSIM/lib/RHEL8', an NEC simulation tree
	# that ships nowhere in the payload) -- scanelf flags the relative
	# component as an rpath security problem. Rewrite it keeping only
	# the two absolute fallbacks, preserving upstream's DT_RPATH type.
	patchelf --force-rpath \
		--set-rpath '/opt/nec/ve/veos/lib64:/opt/nec/ve/mmm/lib64' \
		"${ED}${VE_PREFIX}/td/rt/rtmon"

	insinto /etc/logrotate.d
	doins "${WORKDIR}"/etc/logrotate.d/rt
	fperms 0644 /etc/logrotate.d/rt

	# The RT data tree ships 0640: cata_default, RT.par and the per-slot
	# int/interrupt.ve* seeds.
	insinto /var/opt/nec/ve/td/rt
	doins -r "${WORKDIR}"/var/opt/nec/ve/td/rt/{catalog,int,par}
	local f
	while IFS= read -r -d '' f; do
		fperms 0640 "${f#${ED%/}}"
	done < <(cd "${WORKDIR}" && find var/opt/nec/ve/td/rt/catalog var/opt/nec/ve/td/rt/int var/opt/nec/ve/td/rt/par -type f -print0)

	# rtmon writes the per-slot RT result logs here; logrotate.d/rt
	# rotates them with `su root veadmin`.
	keepdir /var/opt/nec/ve/td/rt/result
}

pkg_postinst() {
	# Upstream ships result/ 0770 and rotates its logs as root:veadmin;
	# the RDEPEND above guarantees the group exists.
	chown root:veadmin "${EROOT}"/var/opt/nec/ve/td/rt/result ||
		ewarn "could not chown ${EROOT}/var/opt/nec/ve/td/rt/result"
	chmod 0770 "${EROOT}"/var/opt/nec/ve/td/rt/result ||
		ewarn "could not chmod ${EROOT}/var/opt/nec/ve/td/rt/result"
	elog "ve_monitor runs ${VE_PREFIX}/td/rt/rtmon for runtime tests"
	elog "(mmm .config: td_rt_exec)."
}
