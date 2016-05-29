/*-
 * Copyright (c) 2016 Alfredo Mazzinghi
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

/*
 * 	CHERI-specific assembly language support routines
 */

#include "opt_ddb.h"
#include <sys/errno.h>
#include <machine/asm.h>
#include <machine/cpu.h>
#include <machine/regnum.h>
#include <machine/cpuregs.h>
#include <machine/pcb.h>
	
#include <machine/cherireg.h>
#include <machine/cheriasm.h>

#include "assym.s"

.set noreorder
	
/*
 * CHERI version of the primitives in mips/support.S
 * The procedures accept capability arguments and behave in the same
 * way as the mips version.
 *
 * XXXAM: Currently the data is assumed to be non-capability, howerver
 * it is desirable to find a way to transparently move capability data
 * as well.
 */
.text

#ifdef CHERI_KERNEL
/*
 * int copystr(kfaddr, kdaddr, maxlen, lencopied)
 *	__capability void *kfaddr,
 *	__capability void *kdaddr,
 *	size_t maxlen,
 *	size_t *lencopied
 * c3 kfaddr, c4 kdaddr, a0 maxlen, c5 *lencopied
 *
 * Copy a NIL-terminated string, at most maxlen characters long.  Return the
 * number of characters copied (including the NIL) in *lencopied.  If the
 * string is too long, return ENAMETOOLONG; else return 0.
 */
LEAF(copystr_cap)
	move		t0, a0			# save maxlen
	beq		a0, zero, 4f
	daddiu		t1, zero, 1
1:
	clbu		v0, zero, 0($c3)
	cincoffset	$c3, $c3, t1
	dsubi		a0, a0, 1
	beqz		v0, 2f			# test end of string
	csb		v0, zero, 0($c4)
	bne		a0, zero, 1b		# less than maxlen
	cincoffset	$c4, $c4, t1
4:
	li		v0, ENAMETOOLONG	# run out of space
2:
	# check if c5 is null
	cfromptr	$c2, $c0, zero
	ceq		t1, $c5, $c2
	bnez		t1, 3f			# return num. of copied bytes
	dsubu		t0, t0, a0		# if lencopied != NULL
	csd		t0, zero, 0($c5)
3:
	j		ra			# v0 is 0 or ENAMETOOLONG
	nop
END(copystr_cap)

/*
 * Copy a null terminated string from the user address space into
 * the kernel address space.
 *
 *	copyinstr(fromaddr, toaddr, maxlength, &lencopied)
 *		__capability char * fromaddr;
 *		__capability char * toaddr;
 *		u_int maxlength;
 *		__capability u_int *lencopied;
 *
 * c3 fromaddr, c4 toaddr, a0 maxlength, c5 *lencopied
 */
NESTED(copyinstr_cap, CALLFRAME_SIZ, ra)
	PTR_SUBU	sp, sp, CALLFRAME_SIZ
	.mask	0x80000000, (CALLFRAME_RA - CALLFRAME_SIZ)
	PTR_LA		v0, copyerr
	cfromptr	$c2, $c0, zero
	clt		t0, $c3, $c2
	bnez		t0, _C_LABEL(copyerr) 	# make sure address is in user space
	REG_S		ra, CALLFRAME_RA(sp)
	GET_CPU_PCPU(v1)
	PTR_L		v1, PC_CURPCB(v1)
	PTR_LA		t9, _C_LABEL(copystr_cap)
	jalr		t9
	PTR_S		v0, U_PCB_ONFAULT(v1)
	REG_L		ra, CALLFRAME_RA(sp)
	GET_CPU_PCPU(v1)
	PTR_L		v1, PC_CURPCB(v1)
	PTR_S		zero, U_PCB_ONFAULT(v1)
	j		ra
	PTR_ADDU	sp, sp, CALLFRAME_SIZ
END(copyinstr_cap)

/*
 * Copy specified amount of data from user space into the kernel
 *	copyin(from, to, len)
 *		__capability char *from;	(user source address)
 *		__capability char *to;	(kernel destination address)
 *		unsigned len;
 */
NESTED(copyin_cap, CALLFRAME_SIZ, ra)
	PTR_SUBU	sp, sp, CALLFRAME_SIZ
	.mask	0x80000000, (CALLFRAME_RA - CALLFRAME_SIZ)
	PTR_LA	v0, copyerr
	cfromptr $c2, $c0, zero
	clt	t0, $c3, $c2
	bnez	t0, _C_LABEL(copyerr) # make sure address is in user space
	REG_S	ra, CALLFRAME_RA(sp)
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_LA	t9, _C_LABEL(bcopy_cap)
	jalr	t9
	PTR_S	v0, U_PCB_ONFAULT(v1)
	REG_L	ra, CALLFRAME_RA(sp)
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)	 	# bcopy modified v1, so reload
	PTR_S	zero, U_PCB_ONFAULT(v1)
	PTR_ADDU	sp, sp, CALLFRAME_SIZ
	j	ra
	move	v0, zero
END(copyin_cap)

/*
 * Copy specified amount of data from kernel to the user space
 *	copyout(from, to, len)
 *		__capability char *from; (kernel source address)
 *		__capability char *to;	(user destination address)
 *		unsigned len;
 */
NESTED(copyout_cap, CALLFRAME_SIZ, ra)
	PTR_SUBU	sp, sp, CALLFRAME_SIZ
	.mask	0x80000000, (CALLFRAME_RA - CALLFRAME_SIZ)
	PTR_LA	v0, copyerr
	cfromptr $c2, $c0, zero
	clt	t0, $c4, $c2
	bnez	t0, _C_LABEL(copyerr) # make sure address is in user space
	REG_S	ra, CALLFRAME_RA(sp)
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_LA	t9, _C_LABEL(bcopy_cap)
	jalr	t9
	PTR_S	v0, U_PCB_ONFAULT(v1)
	REG_L	ra, CALLFRAME_RA(sp)
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)	 	# bcopy modified v1, so reload
	PTR_S	zero, U_PCB_ONFAULT(v1)
	PTR_ADDU	sp, sp, CALLFRAME_SIZ
	j	ra
	move	v0, zero
END(copyout_cap)
	
/*
 * {fu,su},{ibyte,isword,iword}, fetch or store a byte, short or word to
 * user text space.
 * {fu,su},{byte,sword,word}, fetch or store a byte, short or word to
 * user data space.
 *
 * fu[i]{byte,sword,word} (__capability void *base)
 * c3 base
 * su[i]{byte,sword,word} (__capability void *base, long data)
 * c3 base, a0 data
*/

LEAF(fubyte_cap)
/*
 * XXXAM: is the error meaningful here?
 *	can it be mistaken for a -1 byte read normally?
 */	
	PTR_LA		v0, fswberr
	cfromptr	$c2, $c0, zero
	clt		t0, $c3, $c2
	bnez		t0, _C_LABEL(fswberr) 	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L		v1, PC_CURPCB(v1)
	PTR_S		v0, U_PCB_ONFAULT(v1)
	clb		v0, zero, 0($c3)	# load byte
	j		ra
	PTR_S		zero, U_PCB_ONFAULT(v1)
END(fubyte_cap)


LEAF(subyte_cap)
	PTR_LA		v0, fswberr
	cfromptr	$c2, $c0, zero
	clt		t0, $c3, $c2
	bnez		t0, _C_LABEL(fswberr) 	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L		v1, PC_CURPCB(v1)
	PTR_S		v0, U_PCB_ONFAULT(v1)
	csb		a0, zero, 0($c3)	# store byte
	PTR_S		zero, U_PCB_ONFAULT(v1)
	j		ra
	move		v0, zero
END(subyte_cap)


	
#if 0
/*
 * Copy a null terminated string from the kernel address space into
 * the user address space.
 *
 *	copyoutstr(fromaddr, toaddr, maxlength, &lencopied)
 *		caddr_t fromaddr;
 *		caddr_t toaddr;
 *		u_int maxlength;
 *		u_int *lencopied;
 */
NESTED(copyoutstr, CALLFRAME_SIZ, ra)
	PTR_SUBU	sp, sp, CALLFRAME_SIZ
	.mask	0x80000000, (CALLFRAME_RA - CALLFRAME_SIZ)
	PTR_LA	v0, copyerr
	blt	a1, zero, _C_LABEL(copyerr)  # make sure address is in user space
	REG_S	ra, CALLFRAME_RA(sp)
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_LA	t9, _C_LABEL(copystr)
	jalr	t9
	PTR_S	v0, U_PCB_ONFAULT(v1)
	REG_L	ra, CALLFRAME_RA(sp)
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	zero, U_PCB_ONFAULT(v1)
	j	ra
	PTR_ADDU	sp, sp, CALLFRAME_SIZ
END(copyoutstr)

/*
 * {fu,su},{ibyte,isword,iword}, fetch or store a byte, short or word to
 * user text space.
 * {fu,su},{byte,sword,word}, fetch or store a byte, short or word to
 * user data space.
 */
#ifdef __mips_n64
LEAF(fuword64)
XLEAF(fuword)
	PTR_LA	v0, fswberr
	blt	a0, zero, fswberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
	ld	v0, 0(a0)		# fetch word
	j	ra
	PTR_S	zero, U_PCB_ONFAULT(v1)
END(fuword64)
#endif

LEAF(fuword32)
#ifndef __mips_n64
XLEAF(fuword)
#endif
	PTR_LA	v0, fswberr
	blt	a0, zero, fswberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
	lw	v0, 0(a0)		# fetch word
	j	ra
	PTR_S	zero, U_PCB_ONFAULT(v1)
END(fuword32)

LEAF(fusword)
	PTR_LA	v0, fswberr
	blt	a0, zero, fswberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
	lhu	v0, 0(a0)		# fetch short
	j	ra
	PTR_S	zero, U_PCB_ONFAULT(v1)
END(fusword)

LEAF(suword32)
#ifndef __mips_n64
XLEAF(suword)
#endif
	PTR_LA	v0, fswberr
	blt	a0, zero, fswberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
	sw	a1, 0(a0)		# store word
	PTR_S	zero, U_PCB_ONFAULT(v1)
	j	ra
	move	v0, zero
END(suword32)

#ifdef __mips_n64
LEAF(suword64)
XLEAF(suword)
	PTR_LA	v0, fswberr
	blt	a0, zero, fswberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
	sd	a1, 0(a0)		# store word
	PTR_S	zero, U_PCB_ONFAULT(v1)
	j	ra
	move	v0, zero
END(suword64)
#endif

/*
 * casuword(9)
 * <v0>u_long casuword(<a0>u_long *p, <a1>u_long oldval, <a2>u_long newval)
 */
/*
 * casuword32(9)
 * <v0>uint32_t casuword(<a0>uint32_t *p, <a1>uint32_t oldval, 
 *							<a2>uint32_t newval)
 */
LEAF(casuword32)
#ifndef __mips_n64
XLEAF(casuword)
#endif
	PTR_LA	v0, fswberr
	blt	a0, zero, fswberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
1:
	move	t0, a2
	ll	v0, 0(a0)
	bne	a1, v0, 2f
	nop
	sc	t0, 0(a0)		# store word
	beqz	t0, 1b
	nop
	j	3f
	nop
2:
	li	v0, -1
3:
	PTR_S	zero, U_PCB_ONFAULT(v1)
	jr	ra
	nop
END(casuword32)

#ifdef __mips_n64
LEAF(casuword64)
XLEAF(casuword)
	PTR_LA	v0, fswberr
	blt	a0, zero, fswberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
1:
	move	t0, a2
	lld	v0, 0(a0)
	bne	a1, v0, 2f
	nop
	scd	t0, 0(a0)		# store double word
	beqz	t0, 1b
	nop
	j	3f
	nop
2:
	li	v0, -1
3:
	PTR_S	zero, U_PCB_ONFAULT(v1)
	jr	ra
	nop
END(casuword64)
#endif

/*
 * Will have to flush the instruction cache if byte merging is done in hardware.
 */
LEAF(susword)
	PTR_LA	v0, fswberr
	blt	a0, zero, fswberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
	sh	a1, 0(a0)		# store short
	PTR_S	zero, U_PCB_ONFAULT(v1)
	j	ra
	move	v0, zero
END(susword)

LEAF(fswberr)
	j	ra
	li	v0, -1
END(fswberr)

/*
 * fuswintr and suswintr are just like fusword and susword except that if
 * the page is not in memory or would cause a trap, then we return an error.
 * The important thing is to prevent sleep() and switch().
 */
LEAF(fuswintr)
	PTR_LA	v0, fswintrberr
	blt	a0, zero, fswintrberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
	lhu	v0, 0(a0)		# fetch short
	j	ra
	PTR_S	zero, U_PCB_ONFAULT(v1)
END(fuswintr)

LEAF(suswintr)
	PTR_LA	v0, fswintrberr
	blt	a0, zero, fswintrberr	# make sure address is in user space
	nop
	GET_CPU_PCPU(v1)
	PTR_L	v1, PC_CURPCB(v1)
	PTR_S	v0, U_PCB_ONFAULT(v1)
	sh	a1, 0(a0)		# store short
	PTR_S	zero, U_PCB_ONFAULT(v1)
	j	ra
	move	v0, zero
END(suswintr)

LEAF(fswintrberr)
	j	ra
	li	v0, -1
END(fswintrberr)

/*
 * memset(void *s1, int c, int len)
 * NetBSD: memset.S,v 1.3 2001/10/16 15:40:53 uch Exp
 */
LEAF(memset)
	.set noreorder
	blt	a2, 12, memsetsmallclr	# small amount to clear?
	move	v0, a0			# save s1 for result

	sll	t1, a1, 8		# compute  c << 8 in t1
	or	t1, t1, a1		# compute c << 8 | c in 11
	sll	t2, t1, 16		# shift that left 16
	or	t1, t2, t1		# or together

	PTR_SUBU	t0, zero, a0		# compute # bytes to word align address
	and	t0, t0, 3
	beq	t0, zero, 1f		# skip if word aligned
	PTR_SUBU	a2, a2, t0		# subtract from remaining count
	SWHI	t1, 0(a0)		# store 1, 2, or 3 bytes to align
	PTR_ADDU	a0, a0, t0
1:
	and	v1, a2, 3		# compute number of whole words left
	PTR_SUBU	t0, a2, v1
	PTR_SUBU	a2, a2, t0
	PTR_ADDU	t0, t0, a0		# compute ending address
2:
	PTR_ADDU	a0, a0, 4		# clear words
	bne	a0, t0, 2b		#  unrolling loop does not help
	sw	t1, -4(a0)		#  since we are limited by memory speed

memsetsmallclr:
	ble	a2, zero, 2f
	PTR_ADDU	t0, a2, a0		# compute ending address
1:
	PTR_ADDU	a0, a0, 1		# clear bytes
	bne	a0, t0, 1b
	sb	a1, -1(a0)
2:
	j	ra
	nop
	.set reorder
END(memset)

/*
 * bzero(s1, n)
 */
LEAF(bzero)
XLEAF(blkclr)
	.set	noreorder
	blt	a1, 12, smallclr	# small amount to clear?
	PTR_SUBU	a3, zero, a0		# compute # bytes to word align address
	and	a3, a3, 3
	beq	a3, zero, 1f		# skip if word aligned
	PTR_SUBU	a1, a1, a3		# subtract from remaining count
	SWHI	zero, 0(a0)		# clear 1, 2, or 3 bytes to align
	PTR_ADDU	a0, a0, a3
1:
	and	v0, a1, 3		# compute number of words left
	PTR_SUBU	a3, a1, v0
	move	a1, v0
	PTR_ADDU	a3, a3, a0		# compute ending address
2:
	PTR_ADDU	a0, a0, 4		# clear words
	bne	a0, a3, 2b		#  unrolling loop does not help
	sw	zero, -4(a0)		#  since we are limited by memory speed
smallclr:
	ble	a1, zero, 2f
	PTR_ADDU	a3, a1, a0		# compute ending address
1:
	PTR_ADDU	a0, a0, 1		# clear bytes
	bne	a0, a3, 1b
	sb	zero, -1(a0)
2:
	j	ra
	nop
END(bzero)


/*
 * bcmp(s1, s2, n)
 */
LEAF(bcmp)
	.set	noreorder
	blt	a2, 16, smallcmp	# is it worth any trouble?
	xor	v0, a0, a1		# compare low two bits of addresses
	and	v0, v0, 3
	PTR_SUBU	a3, zero, a1		# compute # bytes to word align address
	bne	v0, zero, unalignedcmp	# not possible to align addresses
	and	a3, a3, 3

	beq	a3, zero, 1f
	PTR_SUBU	a2, a2, a3		# subtract from remaining count
	move	v0, v1			# init v0,v1 so unmodified bytes match
	LWHI	v0, 0(a0)		# read 1, 2, or 3 bytes
	LWHI	v1, 0(a1)
	PTR_ADDU	a1, a1, a3
	bne	v0, v1, nomatch
	PTR_ADDU	a0, a0, a3
1:
	and	a3, a2, ~3		# compute number of whole words left
	PTR_SUBU	a2, a2, a3		#   which has to be >= (16-3) & ~3
	PTR_ADDU	a3, a3, a0		# compute ending address
2:
	lw	v0, 0(a0)		# compare words
	lw	v1, 0(a1)
	PTR_ADDU	a0, a0, 4
	bne	v0, v1, nomatch
	PTR_ADDU	a1, a1, 4
	bne	a0, a3, 2b
	nop
	b	smallcmp		# finish remainder
	nop
unalignedcmp:
	beq	a3, zero, 2f
	PTR_SUBU	a2, a2, a3		# subtract from remaining count
	PTR_ADDU	a3, a3, a0		# compute ending address
1:
	lbu	v0, 0(a0)		# compare bytes until a1 word aligned
	lbu	v1, 0(a1)
	PTR_ADDU	a0, a0, 1
	bne	v0, v1, nomatch
	PTR_ADDU	a1, a1, 1
	bne	a0, a3, 1b
	nop
2:
	and	a3, a2, ~3		# compute number of whole words left
	PTR_SUBU	a2, a2, a3		#   which has to be >= (16-3) & ~3
	PTR_ADDU	a3, a3, a0		# compute ending address
3:
	LWHI	v0, 0(a0)		# compare words a0 unaligned, a1 aligned
	LWLO	v0, 3(a0)
	lw	v1, 0(a1)
	PTR_ADDU	a0, a0, 4
	bne	v0, v1, nomatch
	PTR_ADDU	a1, a1, 4
	bne	a0, a3, 3b
	nop
smallcmp:
	ble	a2, zero, match
	PTR_ADDU	a3, a2, a0		# compute ending address
1:
	lbu	v0, 0(a0)
	lbu	v1, 0(a1)
	PTR_ADDU	a0, a0, 1
	bne	v0, v1, nomatch
	PTR_ADDU	a1, a1, 1
	bne	a0, a3, 1b
	nop
match:
	j	ra
	 move	v0, zero
nomatch:
	j	ra
	li	v0, 1
END(bcmp)

#endif /* disabled */	

#endif /* CHERI_KERNEL */
