EAPI=8

# SRPM payload members handed raw to tar (magic-sniffed), as
# sys-libs/glibc-ve1. Must precede inherit (read at inherit time).
RPM_COMPRESS_TYPE="none"

inherit rpm

# Vendor SRPM veoffload-aveorun-ve1 (AVEO 3.6.0): VE-side half of
# AVEO (aveorun_ve1 + libaveoVE/libveohmem + mk/relink helpers).
# aveorun.spec Obsoletes/Provides classic veoffload-veorun -- replaces
# the stale veoffload-veorun git ebuild (stuck at 2.5.0, same bit-rot
# as the veoffload v2.5 repo).
DESCRIPTION="AVEO VE-side runtime (aveorun) for the Vector Engine 1"
HOMEPAGE="https://github.com/veos-sxarr-NEC/veoffload-veorun"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/${PV}/Source/veoffload-aveorun-ve1-${PV}-1.el10.src.rpm"
S="${WORKDIR}/veoffload-aveo-${PV}"

LICENSE="LGPL-2.1"
SLOT="0"

# aveorun.spec Requires: glibc-ve1, libsysve-ve1 (+ BuildRequires
# glibc-ve1-devel). VE links additionally pull -lveio (libsysve) and
# -lveftrace (nec-veperf); ncc injects the veperf/-lsysve set itself,
# mirroring the classic veoffload-veorun ebuild's chain.
DEPEND="sys-libs/glibc-ve1
	dev-libs/libsysve
	dev-libs/nec-veperf-ve1"
RDEPEND="${DEPEND}"
BDEPEND="sys-devel/ncc
	sys-devel/binutils-ve
	sys-libs/glibc-ve1
	dev-libs/libsysve
	dev-libs/nec-veperf-ve1"

# VE ELF (aveorun_ve1, libaveoVE/libveohmem): host strip/scanelf
# cannot process it.
RESTRICT="strip"
QA_PREBUILT="/opt/nec/ve/*"

src_unpack() {
	rpm_unpack "${A}"
	tar -xf "${WORKDIR}"/veoffload-aveo-${PV}.tar.gz -C "${WORKDIR}" ||
		die "inner source tar extraction failed"
}

src_prepare() {
	default
}

# No configure step (plain make, aveorun.spec %build). -j1: prereq
# order (ve-urpc-ve before aveo-ve) is not serial-safe under -j.
# NFORT: upstream links aveorun_* with the Fortran driver for -cxxlib;
# nfort is not in this box's VE SDK subset, and every linked object is
# C (ncc handles -fopenmp/-ftrace itself) -- override with ncc.
# PREF=${T} mirrors the spec's %build PREF=buildroot (dead -L only).
src_compile() {
	local -x PATH=/opt/nec/ve/bin:${PATH}
	emake -j1 all-ve \
		DEST=/opt/nec/ve/veos \
		VEDEST=/opt/nec/ve \
		VEDEST_COM=/opt/nec/ve \
		PREF="${T}" \
		NFORT=/opt/nec/ve/bin/ncc
}

src_install() {
	local -x PATH=/opt/nec/ve/bin:${PATH}
	emake -j1 install-ve \
		DEST=/opt/nec/ve/veos \
		VEDEST=/opt/nec/ve \
		VEDEST_COM=/opt/nec/ve \
		PREF="${D}" \
		NFORT=/opt/nec/ve/bin/ncc
}
