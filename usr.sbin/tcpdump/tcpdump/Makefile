# $FreeBSD$

.include <src.opts.mk>

.if ${MK_CHERI_PURE} == "yes"
WANT_CHERI=pure
.endif

TCPDUMP_DISTDIR?= ${SRCTOP}/contrib/tcpdump
.PATH: ${TCPDUMP_DISTDIR}

PROG=	tcpdump

SRCS=	\
	ascii_strcasecmp.c \
	gmt2local.c \
	machdep.c \
	netdissect.c \
	setsignal.c \
	strtoaddr.c \
	tcpdump.c \
	version.c
CLEANFILES+=	version.c

.include "Makefile.print"

CFLAGS+= -I${.CURDIR} -I${TCPDUMP_DISTDIR}
CFLAGS+= -DHAVE_CONFIG_H
CFLAGS+= -D_U_="__attribute__((unused))"

.if ${MACHINE_CPUARCH} != "i386"
CFLAGS+=	-DLBL_ALIGN
.endif

LIBADD=	l pcap
.if ${MK_CASPER} != "no"
LIBADD+=	casper
LIBADD+=	cap_dns
CFLAGS+=-DHAVE_CASPER
.endif
.if ${MK_OPENSSL} != "no"
LIBADD+=	crypto
CFLAGS+= -I${DESTDIR}/usr/include/openssl
CFLAGS+= -DHAVE_LIBCRYPTO -DHAVE_OPENSSL_EVP_H
.endif

.ifdef OAKLAND2015
CFLAGS+=	-DTCPDUMP_BENCHMARKING
.endif

version.c: ${TCPDUMP_DISTDIR}/VERSION
	rm -f version.c ; \
	    sed 's/.*/char version[] = "&";/' ${TCPDUMP_DISTDIR}/VERSION \
		> version.c

.include <bsd.prog.mk>
