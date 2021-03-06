/* ===-- enable_execute_stack.c - Implement __enable_execute_stack ---------===
 *
 *                     The LLVM Compiler Infrastructure
 *
 * This file is dual licensed under the MIT and the University of Illinois Open
 * Source Licenses. See LICENSE.TXT for details.
 *
 * ===----------------------------------------------------------------------===
 */

#include "int_lib.h"

#ifndef _WIN32
#include <sys/mman.h>
#endif

/* #include "config.h"
 * FIXME: CMake - include when cmake system is ready.
 * Remove #define HAVE_SYSCONF 1 line.
 */
#define HAVE_SYSCONF 1

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#else
#ifndef __APPLE__
#include <unistd.h>
#endif /* __APPLE__ */
#endif /* _WIN32 */

#if __LP64__
	#define TRAMPOLINE_SIZE 48
#else
	#define TRAMPOLINE_SIZE 40
#endif

#ifdef __CHERI_PURE_CAPABILITY__
static const char __enable_execute_stack_warning[]
    __attribute__((section(".gnu.warning.__enable_execute_stack"))) =
    "__enable_execute_stack is unimplemented for CheriABI";
#endif

/*
 * The compiler generates calls to __enable_execute_stack() when creating 
 * trampoline functions on the stack for use with nested functions.
 * It is expected to mark the page(s) containing the address 
 * and the next 48 bytes as executable.  Since the stack is normally rw-
 * that means changing the protection on those page(s) to rwx. 
 */

COMPILER_RT_ABI void
__enable_execute_stack(void* addr)
{

#ifndef __CHERI_PURE_CAPABILITY__
#if _WIN32
	MEMORY_BASIC_INFORMATION mbi;
	if (!VirtualQuery (addr, &mbi, sizeof(mbi)))
		return; /* We should probably assert here because there is no return value */
	VirtualProtect (mbi.BaseAddress, mbi.RegionSize, PAGE_EXECUTE_READWRITE, &mbi.Protect);
#else
#if __APPLE__
	/* On Darwin, pagesize is always 4096 bytes */
	const uintptr_t pageSize = 4096;
#elif !defined(HAVE_SYSCONF)
#error "HAVE_SYSCONF not defined! See enable_execute_stack.c"
#else
        const uintptr_t pageSize = sysconf(_SC_PAGESIZE);
#endif /* __APPLE__ */

	const uintptr_t pageAlignMask = ~(pageSize-1);
	uintptr_t p = (uintptr_t)addr;
	unsigned char* startPage = (unsigned char*)(p & pageAlignMask);
	unsigned char* endPage = (unsigned char*)((p+TRAMPOLINE_SIZE+pageSize) & pageAlignMask);
	size_t length = endPage - startPage;
	(void) mprotect((void *)startPage, length, PROT_READ | PROT_WRITE | PROT_EXEC);
#endif
#endif
}
