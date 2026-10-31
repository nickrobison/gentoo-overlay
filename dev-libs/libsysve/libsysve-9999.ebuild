EAPI=8

inherit autotools git-r3

DESCRIPTION="VE system call library"
HOMEPAGE="https://github.com/veos-sxarr-NEC/libsysve"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/libsysve.git"

LICENSE="MIT"
SLOT="0"

VE_PREFIX="/opt/nec/ve"

# Mirrors libsysve.spec.in glibc/ve1 branch:
#   BuildRequires: veos-headers   -> AC_CHECK_HEADERS([sysve.h veos_defs.h]);
#                                     headers now come from app-accel/veos
#                                     itself (standalone veos-headers pkg
#                                     was dropped in its favour)
#   Requires: glibc-ve1           -> VE programs load libsysve.so against VE libc
# configure.ac defaults CC to ncc (AC_PROG_CC([ncc])), but ncc cannot
# bootstrap this package: its driver injects -lsysve into every link and
# libsysve is what we are building (plus it rejects host x86 CFLAGS).
# gcc-ve links clean with the merged chain (glibc-ve1 + veperf) and
# assembles the .S/.s files through nas, so it breaks the cycle.
RDEPEND="sys-libs/glibc-ve1"
BDEPEND+="
	sys-devel/gcc-ve-bin
	sys-devel/binutils-ve
	app-accel/veos
"

# VE ELF: portage would strip with host binutils; host scanelf cannot
# parse the VE machine type (UNKNOWN_TYPE QA otherwise).
RESTRICT="strip"
QA_PREBUILT="${VE_PREFIX}/*"

src_prepare() {
	default
	# Upstream links the sibling libs with raw -l flags (-lsysve in
	# libveio, -lveio plus a '-sysve' typo gcc-ve rejects in
	# libveaccio), assuming a system libsysve is preinstalled on the
	# build host. Switch to proper libtool LIBADD deps: automake derives
	# link ordering + DEPENDENCIES from them, which also fixes the -jN
	# race (parallel make linked libveio before libsysve.so existed,
	# making the raw -lsysve resolution flaky).
	eapply "${FILESDIR}/libsysve-separatedlibs-libadd.patch"
	eautoreconf
	# --host=ve-nec-linux dies in AC_CANONICAL_HOST (pulled in by
	# LT_INIT): stock config.sub (sys-devel/gnuconfig) does not know
	# NEC's 've' architecture ("machine 've-nec' not recognized").
	# NEC's release tarballs ship a ve-aware copy; git does not.
	# econf refreshes config.guess/sub with `find -type f` scanning
	# WORKDIR only, so a symlinked config.sub (type l) is never
	# replaced and a target outside WORKDIR (${T}) is never found.
	# configure invokes config.sub through /bin/sh (no exec bit needed).
	local cs="${T}/config.sub"
	cp "${EPREFIX}"/usr/share/gnuconfig/config.sub "${cs}" || die
	sed -i '1a if echo "$1" | grep -q "^ve-"; then echo "$1"; exit 0; fi' \
		"${cs}" || die
	local t
	for t in "${S}/build-aux/config.sub" "${S}/config.sub"; do
		if [[ -e ${t} || -L ${t} ]]; then
			ln -sfn "${cs}" "${t}" || die
		fi
	done
}

src_configure() {
	local -x PATH=/opt/nec/ve/bin:${PATH}
	local -x CC=/opt/nec/ve/bin/gcc
	# n/prefixed VE binutils for the cross probes (host ar/strip would
	# otherwise be picked: config.log showed "ve-nec-linux-strip... no").
	local -x AR=nar
	local -x RANLIB=nranlib
	local -x STRIP=nstrip
	# Replace host CFLAGS (-march=skylake etc.): ncc/gcc-ve both fatal on
	# x86 flags. -g -O2 = NEC spec %define optflags.
	local -x CFLAGS="-g -O2"
	# Upstream %build: ./configure --host=ve-nec-linux ... %{_opt}
	# %{_opt} = --enable-separatedlibs on the glibc branch.
	# econf prepends --prefix=/usr --libdir=/usr/lib64; VE consumers
	# (gcc-ve specs, ncc/nld defaults, upstream filelists) all search
	# /opt/nec/ve/{lib,include}, so append ours LAST to win.
	local myconf=(
		--host=ve-nec-linux
		--prefix=/opt/nec/ve
		--libdir=/opt/nec/ve/lib
		--enable-separatedlibs
	)
	econf "${myconf[@]}"
}

src_compile() {
	local -x PATH=/opt/nec/ve/bin:${PATH}
	emake
}

src_install() {
	emake DESTDIR="${ED}" install
}
