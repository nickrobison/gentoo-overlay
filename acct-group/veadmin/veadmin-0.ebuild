EAPI=8

inherit acct-group

DESCRIPTION="Group for NEC's VE MMM (vecmd/ve_monitor) management tree"
KEYWORDS="~amd64"
# acct-group.eclass contributes a conditional IDEPEND (!prefix?); state
# the flag so pkgcheck does not report UnstatedIuse against the profile
# this repo ships.
IUSE="prefix"

# The vendor RPM only runs `groupadd -r veadmin` from its %pre and then
# hands /var/opt/nec/ve/mmm/{log,td} to root:veadmin 770 in %post, so
# this group exists to own those directories. -1: dynamic GID (overlay
# convention; fixed IDs are ::gentoo policy).
ACCT_GROUP_ID=-1
