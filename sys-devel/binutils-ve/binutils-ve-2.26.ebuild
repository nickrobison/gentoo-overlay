
EAPI=8

RPM_COMPRESS_TYPE="none"
inherit rpm

DESCRIPTION="NEC Aurora Binutils (VE)"
HOMEPAGE="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/"
SRC_URI="https://sxauroratsubasa.sakura.ne.jp/repos/community/sdk/sdk_el10/binutils/${PV}-2.12/x86_64/binutils-ve-${PV}-2.12.src.rpm"
S="${WORKDIR}/binutils-ve-${PV}"

LICENSE="GPL-2 GPL-3 LGPL-2.1 LGPL-3"
SLOT="0"
KEYWORDS="~amd64"

VE_PREFIX="/opt/nec/ve"

src_configure() {
	# Mirrors upstream binutils-ve-src.spec: cross tools targeting
	# ve-nec-linux with the n-prefix, built with the host compiler.
	# --libdir: keep libiberty.a under /opt/nec/ve instead of defaults.
	# NOTE: direct configure (not econf): econf would overwrite the
	# tarball's NEC-patched config.sub with gnuconfig's, which rejects
	# the ve-nec-linux target.
	local myconf=(
		--target=ve-nec-linux
		--disable-nls
		# gcc16 warns on 2016-era code; binutils defaults -Werror on
		--disable-werror
		--prefix="${VE_PREFIX}"
		--libdir="${VE_PREFIX}/lib"
		--program-prefix=n
		--with-bugurl=no
	)
	"${S}"/configure "${myconf[@]}" || die "configure failed"
}

src_install() {
	emake DESTDIR="${ED}" install
	# default einstalldocs set misses the license texts
	DOCS=( README ChangeLog COPYING COPYING.LIB COPYING3 COPYING3.LIB )
	einstalldocs

	# Upstream rpm %post hardlinked unprefixed names into
	# ve-nec-linux/bin (portage doesn't run rpm scriptlets)
	dodir "${VE_PREFIX}/ve-nec-linux/bin"
	local n
	for n in nsize nobjdump nar nstrings nranlib nobjcopy naddr2line \
			nreadelf nelfedit nnm nstrip nc++filt nas ngprof nld.bfd nld; do
		dosym "../../bin/${n}" "${VE_PREFIX}/ve-nec-linux/bin/${n#n}"
	done
}
