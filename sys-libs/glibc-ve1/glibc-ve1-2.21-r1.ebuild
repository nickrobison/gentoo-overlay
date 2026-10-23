EAPI=8

RPM_COMPRESS_TYPE="none"
inherit rpm

DESCRIPTION="glibc for the SX-Aurora TSUBASA Vector Engine (VE1), from NEC SRPM source"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/3.6.0/Source/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/TSUBASA-repo_el10.0/veos/3.6.0/Source/${P}-19.el10.src.rpm"
S="${WORKDIR}/${P}"

LICENSE="LGPL-2.1+ GPL-2"
SLOT="0"
# No KEYWORDS: overlay convention (like nec-veperf-3.1.0 and every 9999
# here) -- covered by /etc/portage/package.accept_keywords/sys-libs (* **).
# Keeping ~amd64 would make pkgcheck demand its 9999 BDEPENDs
# (app-accel/veos) solve as keyworded packages.

VE_PREFIX="/opt/nec/ve"
BUILD_DIR="${WORKDIR}/glibc_build"

# VE ELF everywhere (ld-linux-ve.so.1, libc.so.6, crt*.o, ...); host
# strip would choke, crt debug info is removed with nstrip below like
# the spec does.
RESTRICT="strip"
QA_PREBUILT="${VE_PREFIX}/*"
QA_TEXTRELS="opt/nec/ve/*"

# Toolchain for the build (mirrors NEC's glibc.spec: CC=gcc-ve).
# veos: elf/dl-open.c includes <sysve.h>/<veos_defs.h> under __ve__.
# Those headers are authored in veos's include/ and installed by veos to
# /opt/nec/ve/include (default ve_includedir) -- the standalone
# dev-libs/veos-headers package was dropped in favour of this dep.
# NEC's spec omits the BuildRequires because their build host already
# had those headers installed.
# Bootstrap note: link-time crt/libc must already exist under
# /opt/nec/ve/lib -- on the first source build that is the previous
# binary glibc-ve1-2.21 (replaced in-place by this -r1 upgrade), on
# later rebuilds the previously installed copy of this very package.
# That self-hosting is intentionally not expressed as a dependency.
BDEPEND="sys-devel/gcc-ve
	sys-libs/libgcc-ve1-static
	sys-devel/binutils-ve
	sys-kernel/kheaders-ve1
	app-accel/veos"
RDEPEND="sys-kernel/kheaders-ve1"

src_unpack() {
	rpm_unpack "${P}-19.el10.src.rpm"
	# Inner source tarball is a plain tar despite the .gz suffix;
	# portage would gunzip it and fail, tar detects the real format.
	tar -xf "${P}.tar.gz" || die "inner source tar extraction failed"
}

src_prepare() {
	default
	# GNU Make 4.4 re-execs forever when an -included makefile
	# (bits/stdio_lim.d) stays perpetually older than its .st stamp:
	# the stamp recipe does `touch $@` AFTER writing .d/.h, and the
	# .d/.h rule is a no-op `; @:`. Make remakes the makefile each
	# pass, sees it was remade, re-execs, and loops with zero on-disk
	# churn (userspace spin at iconv/assert/ctype/malloc subdir_lib).
	# Make the no-op rules refresh their target so outputs end up
	# newer than the stamp and the loop terminates.
	sed -i \
		-e 's|\$(stdio_lim:lim.h=%.st); @:$|$(stdio_lim:lim.h=%.st); touch $@|' \
		 Makerules || die "sed Makerules stdio_lim rule failed"
	sed -i \
		-e 's|\$(common-objpfx)libc-modules.stmp; @:$|$(common-objpfx)libc-modules.stmp; touch $@|' \
		 Makeconfig || die "sed Makeconfig libc-modules rule failed"
	grep -qF '$(stdio_lim:lim.h=%.st); touch $@' Makerules \
		|| die "stdio_lim rule not patched"
	grep -qF '$(common-objpfx)libc-modules.stmp; touch $@' Makeconfig \
		|| die "libc-modules rule not patched"

	# Stage misc's public <sys/auxv.h> into common-objpfx (BUILD_DIR),
	# which every compile has on -I -- same place glibc itself stages
	# bits/stdio_lim.h. sys/auxv.h is a cross-subdir include (elf's VE
	# dl-machine.h pulls it) reachable neither via elf's -I. (cwd=elf),
	# nor include/ (internal wrappers only, no auxv.h), nor
	# /opt/nec/ve/include (from-scratch bootstrap has no installed
	# glibc headers). -I../include still precedes -I${BUILD}, so
	# include/sys/* internal wrappers keep winning over these.
	mkdir -p "${BUILD_DIR}/sys" || die
	cp "${S}"/misc/sys/auxv.h "${BUILD_DIR}/sys/" || die
}

src_configure() {
	local -x CC="${VE_PREFIX}/bin/gcc"
	mkdir -p "${BUILD_DIR}" || die
	pushd "${BUILD_DIR}" >/dev/null || die
	# Verbatim from NEC glibc.spec %build (rhel>=9 branch), minus rpm
	# macros: CFLAGS="" because host x86 flags are invalid for VE.
	"${S}"/configure \
		CFLAGS="" \
		--prefix="${VE_PREFIX}" \
		--exec-prefix="${VE_PREFIX}" \
		--host=ve-unknown-linux-gnu \
		--with-headers="${VE_PREFIX}/include" \
		--enable-obsolete-rpc \
		LDFLAGS="-Wl,--build-id" \
		|| die "configure failed"
	popd >/dev/null || die
}

src_compile() {
	local -x CC="${VE_PREFIX}/bin/gcc"
	emake -C "${BUILD_DIR}"
}

src_install() {
	emake -C "${BUILD_DIR}" DESTDIR="${ED}" install

	local pre="${ED}${VE_PREFIX}"

	# ld.so configuration (spec %install)
	dodir "/etc/opt/nec/ve/ld.so.conf.d"
	echo 'include ld.so.conf.d/*.conf' > "${ED}/etc/opt/nec/ve/ld.so.conf" || die
	: > "${ED}/etc/opt/nec/ve/ld.so.cache" || die
	chmod 644 "${ED}/etc/opt/nec/ve/ld.so.conf" || die

	# debugger helper is shipped separately upstream
	rm -f "${pre}"/lib/libthread_db*

	# strip debug from startup objects with the VE strip (spec)
	"${VE_PREFIX}/bin/nstrip" -g "${pre}"/lib/*.o || die

	# rpm layout: glibc bins under glibc/{bin,sbin,libexec}, the ldd /
	# ldconfig wrappers stay in the real prefix (spec %install)
	mkdir -p "${pre}/glibc" || die
	mv "${pre}/bin" "${pre}/glibc/bin" || die
	mv "${pre}/sbin" "${pre}/glibc/sbin" || die
	if [[ -d ${pre}/libexec ]]; then
		mv "${pre}/libexec" "${pre}/glibc/libexec" || die
	fi
	mkdir -p "${pre}/bin" "${pre}/sbin" || die
	mv "${pre}/glibc/bin/ve-ldd" "${pre}/bin/" || die
	mv "${pre}/glibc/sbin/ve-ldconfig" "${pre}/sbin/" || die

	# ld.so cache database home
	if [[ -d ${pre}/var ]]; then
		mkdir -p "${ED}/var/opt/nec/ve/glibc" || die
		mv "${pre}"/var/* "${ED}/var/opt/nec/ve/glibc/" || die
		rmdir "${pre}/var" || die
	fi

	rm -f "${pre}/share/info/dir"

	# ticket #1445: whole-archive libpthread for static shm_open()
	# (spec %install: gcc -r + nar)
	pushd "${pre}/lib" >/dev/null || die
	"${VE_PREFIX}/bin/gcc" -r -nostdlib -o libpthread.o \
		-Wl,--whole-archive libpthread.a || die
	rm -f libpthread.a || die
	"${VE_PREFIX}/bin/nar" rcs libpthread.a libpthread.o || die
	rm -f libpthread.o || die
	popd >/dev/null || die
}
