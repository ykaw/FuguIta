bootbin: bootbin.mk bootbin.cache bootbin.c
	${MAKE} ${MFLAGS} -f bootbin.mk all

bootbin.mk bootbin.cache bootbin.c: bootbin.conf
	crunchgen -E -c bootbin.c -e bootbin -m bootbin.mk bootbin.conf

bootbin.conf:
.if $(MACHINE) == "amd64"
	cat ../bootbin.conf.orig.amd64 > bootbin.conf
.else
	cat ../bootbin.conf.orig > bootbin.conf
.endif

.include <bsd.obj.mk>
