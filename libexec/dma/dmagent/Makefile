# $FreeBSD$

.include <src.opts.mk>

.if ${MK_CHERI_USE_LLD} == "no"
# Linker error
WANT_CHERI=none
.endif

LIBADD=	ssl crypto

PROG=	dma
SRCS=	aliases_parse.y \
	aliases_scan.l \
	base64.c \
	conf.c \
	crypto.c \
	dma.c \
	dns.c \
	local.c \
	mail.c \
	net.c \
	spool.c \
	util.c
MAN8=	dma.8
CONFS=	dma.conf
CONFSDIR=	${CONFDIR}/dma
YFLAGS+=	-i
CLEANFILES=	aliases_parse.i
FILES=	mailer.conf
FILESDIR=	${SHAREDIR}/examples/dma
.if ${MK_SENDMAIL} == no
CONFGROUPS=	CONFS MAILER
MAILERDIR=	/etc/mail
MAILER=		mailer.conf
.endif

BINMODE=	2555

.include <bsd.compiler.mk>

.if ${COMPILER_TYPE} == gcc
WARNS=	5
.endif

.include <bsd.prog.mk>
