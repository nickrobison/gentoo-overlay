# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit gnome2-utils xdg

DESCRIPTION="System76 Power Management Extension"
HOMEPAGE="https://github.com/pop-os/gnome-shell-extension-system76-power"
SRC_URI="https://github.com/pop-os/gnome-shell-extension-system76-power/archive/refs/tags/${PV}.tar.gz"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}
"
BDEPEND="dev-lang/typescript"

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
