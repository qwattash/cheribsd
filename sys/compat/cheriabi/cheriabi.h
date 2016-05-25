/*-
 * Copyright (c) 2015 SRI International
 * Copyright (c) 2001 Doug Rabson
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
 * ("CTSRD"), as part of the DARPA CRASH research programme.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * $FreeBSD$
 */

#ifndef _COMPAT_CHERIABI_CHERIABI_H_
#define _COMPAT_CHERIABI_CHERIABI_H_

#include <machine/cheri.h>

#ifndef CHERI_KERNEL
static inline void *
__cheri_cap_to_ptr(struct chericap *c)
{
	void *ptr;

	CHERI_CLC(CHERI_CR_CTEMP0, CHERI_CR_KDC, c, 0);
	CHERI_CTOPTR(ptr, CHERI_CR_CTEMP0, CHERI_CR_KDC);

	return (ptr);
}

/*
 * XXX-BD: We should check lengths and permissions at each invocation of
 * PTRIN and PTRIN_CP.
 */
#define PTRIN(v)        __cheri_cap_to_ptr(&v)
#define PTRIN_CP(src,dst,fld) \
	do { (dst).fld = PTRIN((src).fld); } while (0)
#else

#define PTRIN(v) (void *)v
#define PTRIN_CP(src,dst,fld) \
	do { (dst).fld = PTRIN((src).fld); } while (0)
#endif

#define CP(src,dst,fld) do { (dst).fld = (src).fld; } while (0)

struct kevent_c {
#ifdef CHERI_KERNEL		/* identifier for this event */
	__capability void *ident;
#else
	struct chericap	ident;
#endif
	short		filter;		/* filter for event */
	u_short		flags;
	u_int		fflags;
	int64_t		data;
#ifdef CHERI_KERNEL		/* opaque user data identifier */
	__capability void *udata;
#else
	struct chericap	udata;
#endif
};

struct iovec_c {
#ifdef CHERI_KERNEL
	__capability void *iov_base;
#else
	struct chericap	iov_base;
#endif
	size_t		iov_len;
};

#ifdef CHERI_KERNEL
struct msghdr_c {
	__capability void	    *msg_name;
	socklen_t	             msg_namelen;
	__capability struct iovec_c *msg_iov;
	int		             msg_iovlen;
	__capability void	    *msg_control;
	socklen_t	             msg_controllen;
	int		             msg_flags;
};
#else
struct msghdr_c {
	struct chericap	msg_name;
	socklen_t	msg_namelen;
	struct chericap	msg_iov;
	int		msg_iovlen;
	struct chericap	msg_control;
	socklen_t	msg_controllen;
	int		msg_flags;
};
#endif

#ifdef CHERI_KERNEL
struct jail_c {
	uint32_t	              version;
	__capability char	     *path;
	__capability char	     *hostname;
        __capability char	     *jailname;
	uint32_t	              ip4s;
	uint32_t	              ip6s;
	__capability struct in_addr  *ip4;
	__capability struct in6_addr *ip6;
};
#else
struct jail_c {
	uint32_t	version;
	struct chericap	path;
	struct chericap	hostname;
	struct chericap	jailname;
	uint32_t	ip4s;
	uint32_t	ip6s;
	struct chericap	ip4;
	struct chericap ip6;
};
#endif

struct sigaction_c {
#ifdef CHERI_KERNEL
	/* XXXAM see sigaction for the correct type */
	__capability void * sa_u;
#else
	struct chericap	sa_u;
#endif
	int		sa_flags;
	sigset_t	sa_mask;
};

#ifdef CHERI_KERNEL
struct thr_param_c {
	/* 
	 * XXXAM
	 * this is a function pointer, should be a capability?
	 */
	uintptr_t	   start_func;
	__capability void *arg;
	__capability char *stack_base;
	size_t		   stack_size;
	__capability char *tls_base;
	size_t		   tls_size;
	__capability long *child_tid;
	__capability long *parent_tid;
	int		   flags;
	__capability struct rtptio *rtp;
	__capability void *spare[3];
};
#else
struct thr_param_c {
	uintptr_t	start_func;
	struct chericap	arg;
	struct chericap	stack_base;
	size_t		stack_size;
	struct chericap	tls_base;
	size_t		tls_size;
	struct chericap	child_tid;
	struct chericap	parent_tid;
	int		flags;
	struct chericap	rtp;
	struct chericap	spare[3];
};
#endif

struct mac_c {
	size_t		m_buflen;
#ifdef CHERI_KERNEL
	__capability char *m_string;
#else
	struct chericap	m_string;
#endif
};

#endif /* !_COMPAT_CHERIABI_CHERIABI_H_ */
