#	$OpenBSD: Makefile,v 1.1 1996/06/27 07:20:28 downsj Exp $

PROG=	mount_ext2fs
SRCS=	mount_ext2fs.c getmntopts.c
MAN=	mount_ext2fs.8


MOUNT=	/usr/src/sbin/mount
CFLAGS+= -I${MOUNT}
.PATH:	${MOUNT}

.include <bsd.prog.mk>
# +--------------+
# #	$OpenBSD: Makefile,v 1.1 2014/12/23 17:16:02 deraadt Exp $
# 
# PROG=	mount_vnd
# SRCS=	mount_vnd.c getmntopts.c
# MAN=	mount_vnd.8
# 
# MOUNT=	/usr/src/sbin/mount
# CFLAGS+= -I${MOUNT}
# .PATH:	${MOUNT}
# 
# .PATH:  /usr/src/sbin/mount_vnd
# .include <bsd.prog.mk>
