# bootbin.mk - generated from ../bootbin.conf by crunchgen 0.3

STRIP=strip
LINK=$(LD) -dc -r
LIBS= -L/usr/lib -lutil -lotermcap -ll -lm -ldes
CRUNCHED_OBJS= ksh.lo ln.lo mount.lo mount_ffs.lo mount_cd9660.lo newfs.lo sysctl.lo
SUBMAKE_TARGETS= ksh_make ln_make mount_make mount_ffs_make mount_cd9660_make newfs_make sysctl_make

bootbin: bootbin.o $(CRUNCHED_OBJS)
	$(CC) -static -o $@ bootbin.o $(CRUNCHED_OBJS) $(LIBS)
	$(STRIP) bootbin
all: objs exe
objs: $(SUBMAKE_TARGETS)
exe: bootbin
clean:
	rm -f bootbin *.lo *.o *_stub.c
.PHONY: all objs exe clean $(SUBMAKE_TARGETS)


# -------- ksh

ksh_SRCDIR=/usr/src/bin/ksh
ksh_OBJS= alloc.o c_ksh.o c_sh.o c_test.o c_ulimit.o edit.o emacs.o eval.o exec.o expr.o history.o io.o jobs.o lex.o mail.o main.o mknod.o misc.o path.o shf.o syn.o table.o trap.o tree.o tty.o var.o version.o vi.o
ksh_make:
	cd $(ksh_SRCDIR) && exec $(MAKE) -f Makefile $(ksh_OBJS)

ksh_OBJPATHS= /usr/src/bin/ksh/obj/alloc.o /usr/src/bin/ksh/obj/c_ksh.o /usr/src/bin/ksh/obj/c_sh.o /usr/src/bin/ksh/obj/c_test.o /usr/src/bin/ksh/obj/c_ulimit.o /usr/src/bin/ksh/obj/edit.o /usr/src/bin/ksh/obj/emacs.o /usr/src/bin/ksh/obj/eval.o /usr/src/bin/ksh/obj/exec.o /usr/src/bin/ksh/obj/expr.o /usr/src/bin/ksh/obj/history.o /usr/src/bin/ksh/obj/io.o /usr/src/bin/ksh/obj/jobs.o /usr/src/bin/ksh/obj/lex.o /usr/src/bin/ksh/obj/mail.o /usr/src/bin/ksh/obj/main.o /usr/src/bin/ksh/obj/mknod.o /usr/src/bin/ksh/obj/misc.o /usr/src/bin/ksh/obj/path.o /usr/src/bin/ksh/obj/shf.o /usr/src/bin/ksh/obj/syn.o /usr/src/bin/ksh/obj/table.o /usr/src/bin/ksh/obj/trap.o /usr/src/bin/ksh/obj/tree.o /usr/src/bin/ksh/obj/tty.o /usr/src/bin/ksh/obj/var.o /usr/src/bin/ksh/obj/version.o /usr/src/bin/ksh/obj/vi.o
ksh_stub.c:
	echo "int _crunched_ksh_stub(int argc, char **argv, char **envp){return main(argc,argv,envp);}" >$@
ksh.lo: ksh_stub.o $(ksh_OBJPATHS)
	$(LINK) -o $@ ksh_stub.o $(ksh_OBJPATHS)
	crunchide -k _crunched_ksh_stub $@

# -------- ln

ln_SRCDIR=/usr/src/bin/ln
ln_OBJS= ln.o
ln_make:
	cd $(ln_SRCDIR) && exec $(MAKE) -f Makefile $(ln_OBJS)

ln_OBJPATHS= /usr/src/bin/ln/obj/ln.o
ln_stub.c:
	echo "int _crunched_ln_stub(int argc, char **argv, char **envp){return main(argc,argv,envp);}" >$@
ln.lo: ln_stub.o $(ln_OBJPATHS)
	$(LINK) -o $@ ln_stub.o $(ln_OBJPATHS)
	crunchide -k _crunched_ln_stub $@

# -------- mount

mount_SRCDIR=/usr/src/sbin/mount
mount_OBJS= mount.o
mount_make:
	cd $(mount_SRCDIR) && exec $(MAKE) -f Makefile $(mount_OBJS)

mount_OBJPATHS= /usr/src/sbin/mount/obj/mount.o
mount_stub.c:
	echo "int _crunched_mount_stub(int argc, char **argv, char **envp){return main(argc,argv,envp);}" >$@
mount.lo: mount_stub.o $(mount_OBJPATHS)
	$(LINK) -o $@ mount_stub.o $(mount_OBJPATHS)
	crunchide -k _crunched_mount_stub $@

# -------- mount_ffs

mount_ffs_SRCDIR=/usr/src/sbin/mount_ffs
mount_ffs_OBJS= mount_ffs.o getmntopts.o
mount_ffs_make:
	cd $(mount_ffs_SRCDIR) && exec $(MAKE) -f Makefile $(mount_ffs_OBJS)

mount_ffs_OBJPATHS= /usr/src/sbin/mount_ffs/obj/mount_ffs.o /usr/src/sbin/mount_ffs/obj/getmntopts.o
mount_ffs_stub.c:
	echo "int _crunched_mount_ffs_stub(int argc, char **argv, char **envp){return main(argc,argv,envp);}" >$@
mount_ffs.lo: mount_ffs_stub.o $(mount_ffs_OBJPATHS)
	$(LINK) -o $@ mount_ffs_stub.o $(mount_ffs_OBJPATHS)
	crunchide -k _crunched_mount_ffs_stub $@

# -------- mount_cd9660

mount_cd9660_SRCDIR=/usr/src/sbin/mount_cd9660
mount_cd9660_OBJS= mount_cd9660.o getmntopts.o
mount_cd9660_make:
	cd $(mount_cd9660_SRCDIR) && exec $(MAKE) -f Makefile $(mount_cd9660_OBJS)

mount_cd9660_OBJPATHS= /usr/src/sbin/mount_cd9660/obj/mount_cd9660.o /usr/src/sbin/mount_cd9660/obj/getmntopts.o
mount_cd9660_stub.c:
	echo "int _crunched_mount_cd9660_stub(int argc, char **argv, char **envp){return main(argc,argv,envp);}" >$@
mount_cd9660.lo: mount_cd9660_stub.o $(mount_cd9660_OBJPATHS)
	$(LINK) -o $@ mount_cd9660_stub.o $(mount_cd9660_OBJPATHS)
	crunchide -k _crunched_mount_cd9660_stub $@

# -------- newfs

newfs_SRCDIR=/usr/src/sbin/newfs
newfs_OBJS= dkcksum.o getmntopts.o newfs.o mkfs.o
newfs_make:
	cd $(newfs_SRCDIR) && exec $(MAKE) -f Makefile $(newfs_OBJS)

newfs_OBJPATHS= /usr/src/sbin/newfs/obj/dkcksum.o /usr/src/sbin/newfs/obj/getmntopts.o /usr/src/sbin/newfs/obj/newfs.o /usr/src/sbin/newfs/obj/mkfs.o
newfs_stub.c:
	echo "int _crunched_newfs_stub(int argc, char **argv, char **envp){return main(argc,argv,envp);}" >$@
newfs.lo: newfs_stub.o $(newfs_OBJPATHS)
	$(LINK) -o $@ newfs_stub.o $(newfs_OBJPATHS)
	crunchide -k _crunched_newfs_stub $@

# -------- sysctl

sysctl_SRCDIR=/usr/src/sbin/sysctl
sysctl_OBJS= sysctl.o
sysctl_make:
	cd $(sysctl_SRCDIR) && exec $(MAKE) -f Makefile $(sysctl_OBJS)

sysctl_OBJPATHS= /usr/src/sbin/sysctl/obj/sysctl.o
sysctl_stub.c:
	echo "int _crunched_sysctl_stub(int argc, char **argv, char **envp){return main(argc,argv,envp);}" >$@
sysctl.lo: sysctl_stub.o $(sysctl_OBJPATHS)
	$(LINK) -o $@ sysctl_stub.o $(sysctl_OBJPATHS)
	crunchide -k _crunched_sysctl_stub $@

# ========
