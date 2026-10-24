EAPI=8

# SRPM payload members handed raw to tar (magic-sniffed), same
# approach as sys-libs/glibc-ve1. Must precede inherit (read at
# inherit time).
RPM_COMPRESS_TYPE="none"

inherit rpm

# Vendor SRPM veoffload-aveo (AVEO 3.6.0): NEC's current libveo,
# drop-in VEO replacement over VE-UDMA RPC. Supersedes the bit-rotted
# veos-sxarr-NEC/veoffload git repo (stuck at the 2.5 import, which no
# longer compiles against the current veos/libved headers).
DESCRIPTION="AVEO: VE Offloading Framework based on VE-UDMA RPC (libveo)"
HOMEPAGE="https://github.com/veos-sxarr-NEC/veoffload"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/${PV}/Source/veoffload-aveo-${PV}-1.el10.src.rpm"
S="${WORKDIR}/veoffload-aveo-${PV}"

# aveo.spec License: LGPL (COPYING = LGPLv2.1)
LICENSE="LGPL-2.1"
SLOT="0"

# aveo.spec Requires: veos, libcap (setcap on veo_shmget_helper).
# Build needs only a host C/C++ toolchain (profile compiler) -- the
# spec's BuildRequires: vedebuginfo is referenced nowhere in the build
# (verified by tree-wide grep), and platform-python is only the runtime
# shebang target of gen_veorun_static_symtable.
RDEPEND="app-accel/veos
	sys-libs/libcap"

src_unpack() {
	rpm_unpack "${A}"
	tar -xf "${WORKDIR}"/veoffload-aveo-${PV}.tar.gz -C "${WORKDIR}" ||
		die "inner source tar extraction failed"
}

src_prepare() {
	default
	# aveo.spec %prep pathfix.py -i /usr/bin/python3: python2-era
	# shebang, absent on Gentoo. Build only copies this script; it runs
	# under mk_veorun_static at runtime.
	sed -i '1s|^#!/usr/bin/python$|#!/usr/bin/python3|' \
		"${S}"/scripts/gen_veorun_static_symtable || die
}

# No configure step: plain make with DEST/VEDEST/PREF (aveo.spec
# %build/%install). -j1: `all-vh` prereq order (ve-urpc-vh before
# aveo-vh) is not serial-safe under parallel make. PREF=${T} mirrors
# the spec's %build PREF=buildroot (only feeds a dead -L at compile).
src_compile() {
	emake -j1 all-vh \
		DEST=/opt/nec/ve/veos \
		VEDEST=/opt/nec/ve \
		VEDEST_COM=/opt/nec/ve \
		PREF="${T}"
}

src_install() {
	emake -j1 install-vh \
		DEST=/opt/nec/ve/veos \
		VEDEST=/opt/nec/ve \
		VEDEST_COM=/opt/nec/ve \
		PREF="${D}"
}

pkg_postinst() {
	# aveo.spec %post (rhel>=10): lock the shm helper's pages into RAM.
	# Guarded: setcap lives in sys-libs/libcap (RDEPEND).
	if command -v setcap >/dev/null; then
		setcap cap_ipc_lock+ep "${EROOT}/opt/nec/ve/veos/libexec/veo_shmget_helper" ||
			ewarn "setcap cap_ipc_lock+ep veo_shmget_helper failed"
	fi
}
