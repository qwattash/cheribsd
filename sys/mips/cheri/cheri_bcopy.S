/*-
 * Copyright (c) 2014-2015 Robert N. M. Watson
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory under DARPA/AFRL contract (FA8750-10-C-0237)
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
 */

/* XXXRW: Can I drop some of these? */
#include <machine/asm.h>
#include <machine/cpu.h>
#include <machine/regnum.h>
#include <machine/cpuregs.h>
#include <machine/pte.h>

#ifdef CPU_CHERI
#include <machine/cheriasm.h>
#include <machine/cherireg.h>
#endif

#include "assym.s"

.set noat
.set noreorder

/*
 * Implement CHERI memcpy() and bcopy() variants in assembly; C works fine in
 * the kernel most of the time, but copyincap() and copyoutcap() require that
 * no callee-save registers be trampled over due to fault-based error
 * handling.
 *
 * These routines attempt to handle only fully aligned access, and will throw
 * exceptions if that is not the case.  Likewise, they do not handle
 * overlapping copies, a typical requirement of bcopy() implementations.
 *
 * cheri_bcopy() accepts:
 * a0 - source pointer
 * a1 - destination pointer
 * a2 - length
 *
 * cheri_memcpy() has inverted source/destination pointers.
 */
LEAF(cheri_memcpy)
	move	v0, a0		/* Note cleverness: v0 will hold original... */
	move	a0, a1		/* ... value of a0 for cheri_memcpy(). */
	move	a1, v0

XLEAF(cheri_bcopy)
	beqz	a2, return	/* Return immediately if zero-length. */
	li	v1, -CHERICAP_SIZE	/* Handle under-aligned lengths by... */
	and	a2, a2, v1	/* .. truncating the length to capsize bytes. */
	daddu	a2, a1, a2	/* Branch delay: put end pointer in a2. */
loop:
	clc	CHERI_REG_CTEMP0, a0, 0(CHERI_REG_KDC)
	csc	CHERI_REG_CTEMP0, a1, 0(CHERI_REG_KDC)
	daddiu	a1, a1, CHERICAP_SIZE	/* Increment destination pointer. */
	bne	a1, a2, loop	/* Are we there yet?  If not, loop. */
	daddiu	a0, a0, CHERICAP_SIZE	/* Branch delay: increment src ptr. */
return:
	jr	ra
	nop
END(cheri_memcpy)

#ifdef CHERI_KERNEL
/*
 *	Capability-enabled version of bcopy with capability arguments
 *	__capability void *memcpy(dst, src, len)
 *		__capability char *dst
 *		__capability char *src
 *		unsigned int len
 *	bcopy(src, dst, len)
 * 		__capability char *src
 *		__capability char *dst
 *		unsigned int len
 *
 *	c3 	src address
 *	c4	dst address
 *	a0	length
 */

/*
 * Helpers that compute the frame size given the number of extra
 * integer and capability registers to be saved
 */
NESTED(memcpy_cap, CHERI_FRAME_SIZ(0, 1), ra)
	dsubu	sp, sp, CHERI_FRAME_SIZ(0, 1)
	.mask	0x80000000, (CHERI_FRAME_RA(0, 1) - CHERI_FRAME_SIZ(0, 1))
	sd	ra, CHERI_FRAME_RA(0, 1)(sp)
	/* memcpy has inverted src/dst pointers */
	cmove	$c13, $c3
	cmove	$c3, $c4
	cmove	$c4, $c13
	PTR_LA	t9, _C_LABEL(bcopy_cap)
	jalr	t9
	csc	$c13, sp, 0(CHERI_REG_KDC)
	clc	$c3, sp, 0(CHERI_REG_KDC)
	ld	ra, CHERI_FRAME_RA(0, 1)(sp)
	jr	ra
	daddiu	sp, sp, CHERI_FRAME_SIZ(0, 1)
END(memcpy_cap)

LEAF(bcopy_cap)
	beqz	a0, 3f		/* Return immediately if zero-length. */
	li	v1, -CHERICAP_SIZE	/* Handle under-aligned lengths by... */
	and	t0, a0, v1	/* .. truncating the length to capsize bytes. */
	li	v1, CHERICAP_SIZE
1:
	clc	$c13, zero, 0($c3)
	cincoffset $c3, $c3, v1
	csc	$c13, zero, 0($c4)
	dsubu	t0, t0, v1
	bnez	t0, 1b  	/* loop */
	cincoffset $c4, $c4, v1
	/* we need to copy the remaining length that was not aligned */
	andi	a0, a0, (CHERICAP_SIZE - 1) /* number of extra bytes */
XLEAF(bcopy_misaligned_cap)
	beqz	a0, 3f		/* return if zero length */
	li	v1, 1
2:
	clb	t0, zero, 0($c3)
	cincoffset $c3, $c3, v1
	csb	t0, zero, 0($c4)
	dsubu	a0, a0, v1
	bnez	a0, 2b		/* loop on extra bytes */
	cincoffset $c4, $c4, v1
3:
	jr	ra
	nop
END(bcopy_cap)

#endif /* CHERI_KERNEL */
