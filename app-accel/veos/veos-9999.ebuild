EAPI=8

# python-any-r1: build-time interpreter only (AM_PATH_PYTHON, automake's
# python_PYTHON install, byte-compilation). No impl is pinned anywhere:
# src_configure forces PYTHON=/usr/bin/python3 (the python-exec default),
# so pythondir, any byte-compilation and the installed "#!/usr/bin/python3"
# shebangs all follow whatever the system default is at build time --
# the Gentoo analogue of upstream's RHEL assumption build-python ==
# system-python.
PYTHON_COMPAT=( python3_{10..15} )

inherit autotools git-r3 python-any-r1

DESCRIPTION="NEC Aurora Vector Engine Operating System (VEOS)"
HOMEPAGE="https://github.com/veos-sxarr-NEC/veos"
EGIT_REPO_URI="https://github.com/veos-sxarr-NEC/${PN}.git"

# Upstream ships GPLv2+ (daemon/commands), LGPLv2+ and BSD (libvepseudo),
# MIT (headers subpackage); single-package overlay keeps the union.
LICENSE="GPL-2 LGPL-2.1 BSD MIT"
SLOT="0"

# Mirrors veos.spec.in BuildRequires/Requires with Gentoo equivalents:
#   libved -> app-accel/libved, velayout -> app-accel/velayout,
#   protobuf-c + protobuf-compiler(protoc), log4c, systemd (libudev.h +
#   sd_notify() in src/ived), libuuid -> sys-apps/util-linux,
#   libcap -> sys-libs/libcap, libdhash -> dev-libs/ding-libs, procps-ng,
#   libyaml (AC_CHECK_LIB([yaml])).
# python3-protobuf is RDEPEND below.
# ve-memory-mapping-devel (spec BuildRequires) is not packaged here (no
# open source/RPM access); veos falls back to its in-tree
# vemmagent_fallback.h -- full compile verified green without it.
# sys-libs/musl-ve intentionally NOT a dep: --with-ve-musl-includedir is
# only the install *destination* for veos's own bundled headers
# (include/Makefile.am: ve_musl_include_HEADERS, sources in-tree) and a
# value AC_SUBST'd into the debian packaging manifest. Re-add only if a
# build step starts reading files from that path.
DEPEND="app-accel/libved
	app-accel/velayout
	dev-libs/ding-libs
	dev-libs/libyaml
	dev-libs/log4c
	dev-libs/protobuf-c
	sys-apps/systemd
	sys-apps/util-linux
	sys-libs/libcap
	sys-process/procps"
# python3-protobuf (spec Requires): ve_release_remote_resource.py
# imports veosproto.ived_pb2, whose generated code needs google.protobuf.
# Plain atom like the spec (no impl pinned): whatever target(s) this box
# has enabled, same as /usr/bin/python3's impl.
RDEPEND="${DEPEND}
	dev-python/protobuf"
# protoc generates veos_RPM.pb-c.{c,h} at configure time
# (AC_CONFIG_COMMANDS) and python ived_pb2.py at build time;
# protoc-c itself ships with dev-libs/protobuf-c (in DEPEND).
BDEPEND+="dev-libs/protobuf
	${PYTHON_DEPS}"

# --libdir intentionally NOT /usr/lib64: spec %configure pins
# --libdir=/opt/nec/ve/veos/lib64, matching the ld.so.conf.d/veos.conf
# entry (/opt/nec/ve/veos/lib64) and the vendor veosinfo3 layout.
# veoffload links -lvepseudo/-lveosinfo from that dir (its build needs
# -L there; runtime resolution via the same ld.so.conf.d entry).

src_prepare() {
	default
	eapply "${FILESDIR}"/veos-configure-libproc2.patch \
		"${FILESDIR}"/veos-termios-include.patch \
		"${FILESDIR}"/veos-pids-val.patch
	# Spec %prep runs pathfix.py -i /usr/bin/python3 over the python
	# scripts and their .in templates: shebangs are python2-era
	# "#!/usr/bin/python", absent on Gentoo. Makefile.am's edit rule
	# only substitutes @vars@, so fix the templates themselves. The
	# resulting "#!/usr/bin/python3" stays as-is: python-exec resolves
	# it to the system default impl at runtime -- nothing to pin.
	sed -i '1s|^#!/usr/bin/python$|#!/usr/bin/python3|' \
		"${S}"/scripts/*.in "${S}"/generate-arch_ops.py || die
	eautoreconf
}

src_configure() {
	# python-exec's python3 shim dispatches on EPYTHON; python-any-r1
	# exports EPYTHON=<its selected impl> (may differ from the system
	# default), which would silently redirect /usr/bin/python3 probes to
	# that impl. Unset it everywhere python runs so the shim falls back
	# to the compiled-in system default, then point PYTHON at the shim.
	# Result: pythondir, byte-compilation and "#!/usr/bin/python3"
	# all track the default with no version in the ebuild.
	unset EPYTHON
	local -x PYTHON=/usr/bin/python3

	local myconf=(
		# Destinations only. Defaults for ve-/ve3-includedir already
		# land on /opt/nec/ve{,3}/include (ve_prefix=/opt/nec/ve), so
		# veos takes over the ten headers the standalone
		# dev-libs/veos-headers package used to ship; that ebuild is
		# gone and glibc-ve1/libsysve now BDEPEND on this package.
		--with-ve-musl-includedir=/opt/nec/ve/musl/include
		# Where ve-memory-mapping-devel would install the VEMM agent
		# header; the dir does not exist on this host and the in-tree
		# fallback header covers it.
		--with-vemm-agent-includedir=/opt/nec/ve/veos/include
		# Spec %configure pins this; econf's default --libdir=/usr/lib64
		# must lose, so append LAST.
		--libdir=/opt/nec/ve/veos/lib64
	)

	econf "${myconf[@]}"
}

src_compile() {
	# see src_configure: keep byte-compilation on the system default
	unset EPYTHON
	emake
}

src_install() {
	# see src_configure: install-time py_compile must match pythondir
	unset EPYTHON
	emake DESTDIR="${ED}" install

	# Spec %install drops static/libtool archives from the libdir.
	rm -f "${ED}"/opt/nec/ve/veos/lib64/lib*.a \
		"${ED}"/opt/nec/ve/veos/lib64/lib*.la

	# Spec %files %attr(0444,root,root): feature list is read-only.
	chmod 0444 "${ED}"/usr/share/feature_list || die

	# /var/veos{0..7}-tmp deliberately NOT in the payload: the spec
	# creates them in %post (mode ugo+rwxt) and %postun removes them on
	# uninstall -- mirrored by pkg_postinst/pkg_prerm below. CONTENTS
	# would not preserve the 1777 mode anyway.
}

# Deliberately NOT mirrored from the spec:
# - %pre/%preun VE-offline hardware guards (udevadm os_state checks on
#   /dev/veslot*): only meaningful mid-upgrade on live VE hardware.
# - %post kvm veos_vm.options sed: KVM-guest-only tweak.
# - %post ve-ived restart: the systemd unit ships elsewhere.
# - %post ldconfig: portage runs it automatically (and the relevant
#   /opt/nec/ve/veos/lib64 path is in /etc/ld.so.conf.d/veos.conf).
pkg_postinst() {
	# Spec %post: per-slot runtime dirs (mode ugo+rwxt), then apply the
	# sysctl profile and register the VE binfmt handler now instead of
	# waiting for the next boot.
	local n
	for n in 0 1 2 3 4 5 6 7; do
		install -d -m 1777 "${EROOT}"/var/veos${n}-tmp || die
	done
	if command -v sysctl >/dev/null; then
		sysctl --system >/dev/null 2>&1 || ewarn "sysctl --system failed"
	fi
	if [[ -d /run/systemd/system ]] && command -v systemctl >/dev/null; then
		systemctl restart systemd-binfmt.service >/dev/null 2>&1 ||
			ewarn "could not restart systemd-binfmt; VE binfmt registered at next boot"
	fi
}

# Spec %postun removes the tmp dirs when the package is truly removed
# (rpm $1 == 0); portage runs prerm only on unmerge, never on upgrade.
pkg_prerm() {
	rm -rf "${EROOT}"/var/veos{0..7}-tmp
}
