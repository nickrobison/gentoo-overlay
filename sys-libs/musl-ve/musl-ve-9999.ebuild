
EAPI=8

inherit git-r3 flag-o-matic

DESCRIPTION="Musl libc for the NEC Aurora Vector Engine"
HOMEPAGE="https://github.com/veos-sxarr-NEC/musl-libc-ve"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/musl-libc-ve.git"

LICENSE="MIT"
SLOT="0"

BDEPEND+=" sys-devel/ncc"

VE_PREFIX="/opt/nec/ve/musl"

# VE objects: host strip/scanelf cannot process them.
RESTRICT="strip"
QA_PREBUILT="/opt/nec/ve/*"

src_configure() {
	strip-flags
	filter-flags -pipe
	local -x CFLAGS="-g -O0 -mno-vector -fcfi-sections=debug_frame"
	append-ldflags -Wl,--build-id -Wl,-z,max-page-size=0x200000
	local myconf=(
		--prefix="${VE_PREFIX}"
		--exec-prefix="/opt/nec/ve"
		--disable-optimize
		--target=ve
	)

	"${S}/configure" "${myconf[@]}" || die
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${ED}" install

}
