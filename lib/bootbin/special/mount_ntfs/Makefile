#	$OpenBSD: Makefile,v 1.7 2007/12/09 19:48:55 martin Exp $

.if (${MACHINE} == "alpha" || ${MACHINE} == "amd64" || ${MACHINE} == "i386" || ${MACHINE} == "arm64" || ${MACHINE} == "macppc")
PROG=	mount_ntfs
SRCS=	mount_ntfs.c getmntopts.c
.else
NOPROG=
.endif

MOUNT=	/usr/src/sbin/mount
CFLAGS+= -I${MOUNT}
.PATH:	${MOUNT} /usr/src/sbin/mount_ntfs

.include <bsd.prog.mk>
