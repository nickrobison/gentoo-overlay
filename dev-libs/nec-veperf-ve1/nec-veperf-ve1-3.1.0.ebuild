EAPI=8

RPM_COMPRESS_TYPE="xz"
inherit rpm

DESCRIPTION="SX-Aurora VE1 veperf performance-counter libraries (runtime + devel)"
HOMEPAGE="https://www.nec.com/en/global/products/micro/ve/"
SRC_URI="
	https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/tuningtool/251020/nec-veperf-ve1-libs-${PV}-2.x86_64.rpm
	https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/tuningtool/251020/nec-veperf-ve1-devel-${PV}-2.x86_64.rpm
"
S="${WORKDIR}"

SLOT="0"
# No KEYWORDS: overlay convention (see sys-libs/glibc-ve1) -- covered by
# /etc/portage/package.accept_keywords/dev-libs (* **); keywording it
# would make pkgcheck demand its keywordless glibc-ve1 RDEPEND solve.

VE_PREFIX="/opt/nec/ve"

# VE ELF shared objects and archives: host strip/soname QA would choke.
RESTRICT="strip"
QA_PREBUILT="${VE_PREFIX}/*"

# Single Gentoo package out of the upstream -libs/-devel RPM split:
# devel's unversioned libveproginf.so/libveperfcnt.so stubs (what ncc's
# default -lveproginf -lveperfcnt link set resolves against) live
# together with the runtime .so.1 objects, so nothing dangles.
# VE programs link them against VE libc.
RDEPEND="sys-libs/glibc-ve1"

src_unpack() {
	default
	rpm_unpack "nec-veperf-ve1-libs-${PV}-2.x86_64.rpm"
	rpm_unpack "nec-veperf-ve1-devel-${PV}-2.x86_64.rpm"
}

src_install() {
	# Payload: opt/nec/ve/{include/ftrace.h, lib/libve*{,.so,.a,.so.1,.so.1.0.0}};
	# usr/ build-id links dropped.
	[[ -d ${S}/opt ]] || die "unexpected rpm layout"
	mv "${S}/opt" "${ED}" || die
}
