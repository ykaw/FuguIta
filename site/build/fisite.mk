BUILDMAKE ?= ${MAKE}
PREFIX     = /usr/fuguita
PROGS      = rsync rlwrap pv
VER       != uname -r | tr -dc 0-9
SITE_TGZ   = site${VER}.tgz

${SITE_TGZ}:
	touch install_start
	${MAKE} build_install
	touch install_end
	tar cvzf ../${SITE_TGZ} $$(find ${PREFIX} \( -type f -o -type l \) -cnewer install_start ! -cnewer install_end -print | sort)

build_install: ${PROGS}

rsync: xxhash
	test -n "${RSYNC}"
	CFLAGS=-I${PREFIX}/include LDFLAGS=-L${PREFIX}/lib ${MAKE} install PROG=${RSYNC} CONFIG_OPTS="--disable-lz4 --disable-zstd"

xxhash:
	test -n "${XXHASH}"
	${MAKE} install PROG=${XXHASH} BUILDMAKE=gmake NO_CONFIGURE=1 INSTALLPREFIX=${PREFIX}
	ldconfig -m ${PREFIX}/lib

rlwrap:
	test -n "${RLWRAP}"
	${MAKE} install PROG=${RLWRAP}

pv:
	test -n "${PV}"
	${MAKE} install PROG=${PV}

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
	${MAKE} distclean PROG=${XXHASH}
	${MAKE} distclean PROG=${RSYNC}
	${MAKE} distclean PROG=${RLWRAP}
	${MAKE} distclean PROG=${PV}
	rm -f install_start install_end ../${SITE_TGZ} *~ *.bak

distclean:
.ifdef PROG
	rm -rf ${PROG}
.endif
