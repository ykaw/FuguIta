#	$OpenBSD: Makefile,v 1.8 2016/03/30 06:38:43 jmc Exp $

PROG=	newfs
SRCS=	dkcksum.c getmntopts.c newfs.c mkfs.c
MAN=	newfs.8

MOUNT=	/usr/src/sbin/mount
CFLAGS+=-DMFS -I${MOUNT}
.PATH:	${MOUNT} /usr/src/sbin/disklabel

DPADD=	${LIBUTIL}
LDADD=	-lutil

#LINKS=	${BINDIR}/newfs ${BINDIR}/mount_mfs

.include <bsd.prog.mk>
