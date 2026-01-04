bootbin: bootbin.mk bootbin.cache bootbin.c
	${MAKE} ${MFLAGS} -f bootbin.mk all

bootbin.mk bootbin.cache bootbin.c: bootbin.conf
	crunchgen -E -c bootbin.c -e bootbin -m bootbin.mk bootbin.conf

bootbin.conf:
	cp ../bootbin.conf.orig.$(MACHINE) bootbin.conf

.include <bsd.obj.mk>
