/*-
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (c) 1993, David Greenman
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef _SYS_IMGACT_H_
#define	_SYS_IMGACT_H_

#include <sys/_uio.h>

#include <vm/vm.h>

#define MAXSHELLCMDLEN	PAGE_SIZE

struct ucred;

struct image_args {
	char *buf;		/* pointer to string buffer */
	void *bufkva;		/* cookie for string buffer KVA */
	char *begin_argv;	/* beginning of argv in buf */
	char *begin_envv;	/* (interal use only) beginning of envv in buf,
				 * access with exec_args_get_begin_envv(). */
	char *endp;		/* current `end' pointer of arg & env strings */
	char *fname;            /* pointer to filename of executable (system space) */
	char *fname_buf;	/* pointer to optional malloc(M_TEMP) buffer */
	int stringspace;	/* space left in arg & env buffer */
	int argc;		/* count of argument strings */
	int envc;		/* count of environment strings */
	int fd;			/* file descriptor of the executable */
};

struct image_params {
	struct proc *proc;		/* our process */
	struct label *execlabel;	/* optional exec label */
	struct vnode *vp;		/* pointer to vnode of file to exec */
	struct vm_object *object;	/* The vm object for this vp */
	struct vattr *attr;		/* attributes of file */
	const char *image_header;	/* header of file to exec */
	unsigned long entry_addr;	/* entry address of target executable */
	unsigned long start_addr;	/* start of mapped image (including bss) */
	unsigned long end_addr;		/* end of mapped image (including bss) */
	unsigned long reloc_base;	/* load address of image */
	unsigned long et_dyn_addr;	/* PIE load base */
	unsigned long interp_start;	/* start of RTLD mapping (or zero) */
	unsigned long interp_end;	/* end of RTLD mapping (or zero) */
	char *interpreter_name;		/* name of the interpreter */
	void *auxargs;			/* ELF Auxinfo structure pointer */
	struct sf_buf *firstpage;	/* first page that we mapped */
	void * __capability strings;	/* pointer to string space (user) */
	void * __capability ps_strings;	/* pointer to ps_string (user space) */
	struct image_args *args;	/* system call arguments */
	struct sysentvec *sysent;	/* system entry vector */
	void * __capability argv;	/* pointer to argv (user space) */
	void * __capability envv;	/* pointer to envv (user space) */
	void * __capability auxv;	/* pointer to auxv (user space) */
	char *execpath;
	void * __capability execpathp;
	char *freepath;
	void * __capability canary;
	int canarylen;
	void * __capability pagesizes;
	int pagesizeslen;
	struct cheri_c18n_info * __kerncap c18n_info;
	void * __capability stack;
	vm_prot_t stack_prot;
	u_long stack_sz;
	struct ucred *newcred;		/* new credentials if changing */
#define IMGACT_SHELL	0x1
#define IMGACT_BINMISC	0x2
	unsigned char interpreted;	/* mask of interpreters that have run */
	bool credential_setid;		/* true if becoming setid */
	bool vmspace_destroyed;		/* we've blown away original vm space */
	bool opened;			/* we have opened executable vnode */
	bool textset;
	u_int map_flags;
	void * __capability imgact_capability;	/* copyout and mapping cap */
#define IMGP_ASLR_SHARED_PAGE	0x1
	uint32_t imgp_flags;
	struct vnode *interpreter_vp;	/* vnode of the interpreter */
};

#ifdef _KERNEL
struct sysentvec;
struct thread;
struct vmspace;

int	exec_alloc_args(struct image_args *);
int	exec_args_add_arg(struct image_args *args,
	    const char * __capability argp, enum uio_seg segflg);
int	exec_args_add_env(struct image_args *args,
	    const char * __capability envp, enum uio_seg segflg);
int	exec_args_add_fname(struct image_args *args,
	    const char *__capability fname, enum uio_seg segflg);
int	exec_args_adjust_args(struct image_args *args, size_t consume,
	    ssize_t extend);
char	*exec_args_get_begin_envv(struct image_args *args);
int	exec_check_permissions(struct image_params *);
void	exec_cleanup(struct thread *td, struct vmspace *);
int	exec_copyout_strings(struct image_params *, uintcap_t *);
void	exec_free_args(struct image_args *);
int	exec_map_stack(struct image_params *);
int	exec_new_vmspace(struct image_params *, struct sysentvec *);
void	exec_setregs(struct thread *, struct image_params *, uintcap_t);
int	exec_shell_imgact(struct image_params *);
int	exec_copyin_args(struct image_args *, const char * __capability,
	    enum uio_seg, void * __capability, void * __capability);
int	pre_execve(struct thread *td, struct vmspace **oldvmspace);
void	post_execve(struct thread *td, int error, struct vmspace *oldvmspace);
#endif

#endif /* !_SYS_IMGACT_H_ */
// CHERI CHANGES START
// {
//   "updated": 20230509,
//   "target_type": "header",
//   "changes": [
//     "support"
//   ],
//   "change_comment": ""
// }
// CHERI CHANGES END
