# $FreeBSD$

.include <src.opts.mk>

.if ${MK_CHERI_USE_LLD} == "no"
# Linker error
WANT_CHERI=none
.endif

# Vendor sources and generated files
LDNSDIR= ${SRCTOP}/contrib/ldns
UNBOUNDDIR= ${SRCTOP}/contrib/unbound

.PATH: ${UNBOUNDDIR} ${UNBOUNDDIR}/smallapp ${UNBOUNDDIR}/util ${UNBOUNDDIR}/doc

PROG=	unbound-checkconf
SRCS=	ub_event.c unbound-checkconf.c worker_cb.c
CFLAGS+=	-I${UNBOUNDDIR} -I${LDNSDIR}
LIBADD=	unbound pthread
MAN=	unbound-checkconf.8

.include <bsd.prog.mk>
