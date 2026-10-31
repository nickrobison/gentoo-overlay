EAPI=8

inherit git-r3

DESCRIPTION="GCC 7.1.0 for the SX-Aurora TSUBASA Vector Engine, built from source"
HOMEPAGE="https://github.com/veos-sxarr-NEC/gcc-ve"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/gcc-ve.git"
EGIT_BRANCH=master

LICENSE="GPL-3"
SLOT="0"
# No KEYWORDS: live ebuild, overlay convention -- granted ** via
# /etc/portage/package.accept_keywords/sys-devel (targeted line; a
# sys-devel/* wildcard would expose gentoo live ebuilds too).

VE_PREFIX="/opt/nec/ve"
# Staging prefix: installs side-by-side with sys-devel/gcc-ve-bin (which
# owns ${VE_PREFIX}/{bin,lib}) so both toolchains can be present while
# the source build is being proven. Flip --prefix to ${VE_PREFIX} when
# the source compiler replaces the binary package; the vendor specs
# search paths below are absolute, so they keep working either way.
STAGE_PREFIX="${VE_PREFIX}/gcc-ve"
BUILD_DIR="${WORKDIR}/gcc_build"

# Mixed tree under one prefix: host x86_64 executables (gcc driver,
# cc1/cc1plus) next to VE target objects (crt*, libgcc.a,
# libstdc++.a). Host strip/scanelf cannot parse the VE machine type.
# Host ELF is trimmed manually in src_install instead.
RESTRICT="strip test"
QA_PREBUILT="${STAGE_PREFIX}/*"

# Out-of-tree build (gcc forbids in-tree). VE binutils for the
# --with-as/--with-ld paths baked into the driver; host gmp/mpfr/mpc
# (the git tree carries no in-tree copies, unlike release tarballs);
# bison/flex regenerate the parsers (git has no pregenerated ones).
DEPEND="
	sys-devel/binutils-ve
	dev-libs/gmp
	dev-libs/mpfr
	dev-libs/mpc
	sys-devel/bison
	sys-devel/flex
"
# The driver shells out to nas/nld to assemble and link VE output.
RDEPEND="sys-devel/binutils-ve"

# gcc's target-tool probes accept ve-nec-linux-gnu-{ar,ranlib,strip,...}
# names without checking they exist (target libgcc Makefile got
# AR = ve-nec-linux-gnu-ar, then libgcov.a died with 127). binutils-ve
# ships the same tools as nar/nstrip/nnm/... -- bridge the naming.
# Exported PATH must cover configure AND make time: target-subdir
# configures and Makefile recipes both exec these names directly.
ve_xtools() {
	local t
	mkdir -p "${T}/xtools" || die
	for t in ar ranlib strip objcopy objdump readelf nm size strings \
		addr2line ld as; do
		ln -sf "${VE_PREFIX}/bin/n${t}" \
			"${T}/xtools/ve-nec-linux-gnu-${t}" || die
	done
	export PATH="${T}/xtools:${PATH}"
}

src_prepare() {
	default
	# crt1.o/crti.o/crtn.o ship with VE glibc at /opt/nec/ve/lib. The
	# staging prefix's own tooldir/lib is empty, and ld never resolves
	# a bare crt1.o through -L: -L only feeds -l searches (verified
	# against both host GNU ld and nld); explicit .o inputs must arrive
	# as absolute paths from the driver's startfile search (crtbegin.o
	# got that treatment, crt1.o came back bare and nld choked).
	# Two gcc.c changes cooperate: retarget the default startfile
	# prefix at the VE libc, and let that prefix list be installed
	# for cross builds -- stock gcc only adds it when native or when
	# a sysroot is set (vendor never noticed: their prefix/lib WAS
	# the glibc dir via the unconditional tooldir add). The relative
	# prefix branch keeps its own native guard, so only the absolute
	# VE path is picked up.
	sed -i 's|STANDARD_STARTFILE_PREFIX_1 "/lib/"|STANDARD_STARTFILE_PREFIX_1 "/opt/nec/ve/lib/"|' \
		"${S}/gcc/gcc.c" || die "sed startfile prefix failed"
	sed -i "s#else if (\*cross_compile == '0' || target_system_root)#else if (1)#" \
		"${S}/gcc/gcc.c" || die "sed cross startfile gate failed"
	grep -qF 'STANDARD_STARTFILE_PREFIX_1 "/opt/nec/ve/lib/"' "${S}/gcc/gcc.c" \
		|| die "startfile prefix not patched"
	grep -qF 'else if (1)' "${S}/gcc/gcc.c" \
		|| die "cross startfile gate not patched"
}

src_configure() {
	ve_xtools
	# gcc-7's own C++ predates gnu++17 (gcc-config default slot is 16):
	# build with the -14 slot in gnu++11 mode to keep the host compiler
	# from rejecting 2017-era constructs.
	local -x CC=gcc-14 CXX=g++-14
	local -x CFLAGS="-O2"
	local -x CXXFLAGS="-O2 -std=gnu++11"

	# Configure in place across retries: gcc objects are expensive and
	# the flag set is stable; wiped only by ebuild clean.
	mkdir -p "${BUILD_DIR}" || die
	cd "${BUILD_DIR}" || die

	# Baseline = the vendor rpm's configure line (recover with
	# /opt/nec/ve/bin/gcc -v), minus rpm-ism, plus deliberate
	# trimming: no bootstrap (cross build), c/C++ only, no frill
	# target libraries, no NLS, no info pages, no multilib, release
	# checking. --program-prefix= undoes autoconf's cross default of
	# ${target}- prefixed program names (vendor passes it too).
	# -idirafter (not -isystem) for the VE glibc headers: they must
	# sort AFTER the C++ dirs so libstdc++'s #include_next
	# <stdlib.h> chains onto them -- -isystem lands first and gets
	# overshoot; --with-native-system-header-dir was tried and
	# nuked the standard chain entirely on this tree. -L stays for
	# target-lib link tests; vendored specs add the
	# linker/dynamic-linker bits at runtime.
	"${S}"/configure \
		--target=ve-nec-linux-gnu \
		--prefix="${STAGE_PREFIX}" \
		--with-local-prefix="${STAGE_PREFIX}" \
		--enable-languages=c,c++ \
		--enable-libstdc++-v3 \
		--disable-shared \
		--enable-static \
		--enable-sjlj-exceptions \
		--disable-libunwind-exceptions \
		--enable-tls \
		--with-as="${VE_PREFIX}/bin/nas" \
		--with-ld="${VE_PREFIX}/bin/nld" \
		--with-specs="-idirafter ${VE_PREFIX}/include -L${VE_PREFIX}/lib" \
		--program-prefix= \
		--disable-bootstrap \
		--disable-multilib \
		--disable-nls \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libatomic \
		--disable-libitm \
		--disable-libsanitizer \
		--disable-libvtv \
		--disable-libcilkrts \
		--disable-installed-libiberty \
		--disable-werror \
		--without-isl \
		--enable-checking=release \
		MAKEINFO=true \
		|| die "configure failed"
}

src_compile() {
	ve_xtools
	cd "${BUILD_DIR}" || die
	# all-host before all: the top-level `all` runs host and target
	# prerequisites concurrently under -j, so a source-level driver
	# tweak (startfile prefix sed) could miss target-subdir configures
	# that start with the stale xgcc.
	emake all-host || die "host-side build failed"
	emake
}

src_install() {
	ve_xtools
	cd "${BUILD_DIR}" || die
	emake install DESTDIR="${ED}" MAKEINFO=true || die

	local pre="${ED}${STAGE_PREFIX}"

	[[ -x ${pre}/bin/gcc ]] || die "gcc driver missing after install"

	# Vendor driver behaviour: the specs file from the binary package
	# injects -isystem/-L plus the VE dynamic linker wiring. gcc reads
	# it from its own versioned libdir at runtime; the version dir is
	# the compiler's (7.1.0), not ${PV}.
	local gcclib
	gcclib=( "${pre}"/lib/gcc/ve-nec-linux-gnu/*/ )
	[[ -e ${gcclib[0]}/crtbegin.o ]] || die "VE crtbegin.o not installed"
	cp "${FILESDIR}/specs" "${gcclib[0]}/specs" || die "specs install failed"
	# Vendor specs inject -isystem /opt/nec/ve/include via *cpp, which
	# sorts BEFORE the C++ dirs; libstdc++'s #include_next <stdlib.h>
	# only chains forward from its position and overshoots. glibc
	# headers reach the standard slot now via
	# --with-native-system-header-dir, so drop the early injection
	# from the installed copy (repo file stays verbatim vendor).
	sed -i 's|%{!nostdinc:-isystem /opt/nec/ve/include}||' \
		"${gcclib[0]}/specs" || die "sed specs include failed"

	# Frill trim (smallest possible install): texinfo output, man
	# pages (built from the same texi), docs, locales (nls is off,
	# dirs may still exist), gdb pretty-printer python, host
	# libiberty.a (flag may have already skipped it).
	rm -rf "${pre}"/share || die
	rm -f "${pre}"/lib/libiberty.a

	# Host ELF trim: only bin/ and libexec/ hold x86_64 objects;
	# lib/ and lib/gcc/ are VE archives/objects (host strip would
	# choke), and RESTRICT=strip keeps portage's off them too.
	local f
	while IFS= read -r -d '' f; do
		if file -b "${f}" | grep -q 'ELF 64-bit'; then
			strip --strip-unneeded "${f}" || die "strip failed: ${f}"
		fi
	done < <(find "${pre}/bin" "${pre}/libexec" -type f -print0)
}
