EAPI=8

inherit acct-user

DESCRIPTION="Account for NEC's VE MMM (vecmd/ve_monitor) management tree"
KEYWORDS="~amd64"
# acct-user.eclass contributes a conditional IDEPEND (!prefix?); state
# the flag so pkgcheck does not report UnstatedIuse against the profile
# this repo ships.
IUSE="prefix"

# The vendor RPM ships no veadmin *user* -- only the group of the same
# name (see acct-group/veadmin). This package adds the matching account
# as an ownership/audit principal for the MMM state tree, kept a plain
# system account: nologin shell and /dev/null home are the eclass
# defaults, and the things veadmin owns (/var/opt/nec/ve/mmm/{log,td})
# belong to the group anyway. Switch ACCT_USER_SHELL/_HOME here if it
# should become a login operator account instead.
# -1: dynamic UID (overlay convention; fixed IDs are ::gentoo policy).
ACCT_USER_ID=-1
ACCT_USER_GROUPS=( veadmin )

acct-user_add_deps
