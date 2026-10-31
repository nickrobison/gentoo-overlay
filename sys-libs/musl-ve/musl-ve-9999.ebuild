
EAPI=8

inherit autotools git-r3 flag-o-matic

DESCRIPTION="Musl libc for NEV Aurora"
HOMEPAGE="https://github.com/veos-sxarr-NEC/musl-libc-ve"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/musl-libc-ve.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND="sys-devel/ncc"

VE_PREFIX="/opt/nec/ve/musl"

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

	./configure "${myconf[@]}"
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${ED}" install

}
