BUILDMAKE ?= ${MAKE}
PREFIX = /usr/fuguita
PROGS = rsync rlwrap pv
VER=76
SITE_TGZ=site${VER}.tgz

${SITE_TGZ}:
	touch install_start
	${MAKE} build_install
	touch install_end
	tar cvzf ../${SITE_TGZ} $$(find ${PREFIX} \( -type f -o -type l \) -cnewer install_start ! -cnewer install_end -print | sort)

build_install: ${PROGS}

rsync: xxhash
	CFLAGS=-I${PREFIX}/include LDFLAGS=-L${PREFIX}/lib ${MAKE} install PROG=rsync-3.3.0 CONFIG_OPTS="--disable-lz4 --disable-zstd"

xxhash:
	${MAKE} install PROG=xxHash-0.8.2 BUILDMAKE=gmake NO_CONFIGURE=1 INSTALLPREFIX=${PREFIX}

rlwrap:
	${MAKE} install PROG=rlwrap-0.46.1

pv:
	${MAKE} install PROG=pv-1.8.5

install: build
.ifdef INSTALLPREFIX
	cd ${PROG} && ${BUILDMAKE} install prefix=${INSTALLPREFIX}
.else
	cd ${PROG} && ${BUILDMAKE} install
.endif

build: configure
	cd ${PROG} && ${BUILDMAKE}

configure: extract
.ifndef NO_CONFIGURE
	cd ${PROG} && ./configure --prefix=${PREFIX} ${CONFIG_OPTS}
.endif

extract: ${PROG}.tar.gz
	tar xvzf  ${PROG}.tar.gz

allclean:
	${MAKE} distclean PROG=xxHash-0.8.2
	${MAKE} distclean PROG=rsync-3.3.0
	${MAKE} distclean PROG=rlwrap-0.46.1
	${MAKE} distclean PROG=pv-1.8.5
	rm -f install_start install_end ${SITE_TGZ} *~ *.bak

distclean:
.ifdef PROG
	rm -rf ${PROG}
.endif
