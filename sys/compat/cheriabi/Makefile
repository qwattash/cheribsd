# Makefile for syscall tables
#
# $FreeBSD$

SYS_MASTER ?= syscalls.master

all:
	@echo "make sysent only"

sysent:  cheriabi_sysent.c cheriabi_syscall.h cheriabi_proto.h cheriabi_systrace_args.c cheriabi_sysargmap.c

cheriabi_sysent.c cheriabi_syscalls.c cheriabi_syscall.h cheriabi_proto.h cheriabi_systrace_args.c cheriabi_sysargmap.c: \
	    ../../kern/makesyscalls.sh $(SYS_MASTER) syscalls.conf
	sh ../../kern/makesyscalls.sh $(SYS_MASTER) syscalls.conf

clean:
	rm -f cheriabi_sysent.c cheriabi_syscalls.c cheriabi_syscall.h cheriabi_proto.h
	rm -f cheriabi_systrace_args.c cheriabi_sysargmap.c
