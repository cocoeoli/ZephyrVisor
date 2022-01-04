/*
 * Copyright (c) 2019 Carlo Caione <ccaione@baylibre.com>
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <toolchain.h>
#include <linker/sections.h>
#include <arch/cpu.h>
#include "boot.h"
#include "macro_priv.inc"

_ASM_FILE_PROLOGUE

/*
 * Platform specific pre-C init code
 *
 * Note: - Stack is not yet available
 *       - x23, x24 and x25 must be preserved
 */

WTEXT(z_arm64_el3_plat_prep_c)					//宏定义
SECTION_FUNC(TEXT,z_arm64_el3_plat_prep_c)
	ret

WTEXT(z_arm64_el2_plat_prep_c)
SECTION_FUNC(TEXT,z_arm64_el2_plat_prep_c)
	ret

WTEXT(z_arm64_el1_plat_prep_c)
SECTION_FUNC(TEXT,z_arm64_el1_plat_prep_c)
	ret

/*
 * Set the minimum necessary to safely call C code
 * edit the __reset_prep_c, make it run in EL2
 */

GTEXT(__reset_prep_c)
SECTION_SUBSEC_FUNC(TEXT,_reset_section,__reset_prep_c)
	/* return address: x23 */
	mov	x23, x30

	/*
	 * If zvm protected mode is initialized, all CPUs must have been booted
	 * in EL2. Avoid checking __boot_cpu_mode as CPUs now come up in EL1.
	 */

	/*Call hvc */
	/****pretend it move to el2****/
	/*xiong end */

	switch_el x0, 3f, 2f, 1f
3:
	/* Reinitialize SCTLR from scratch in EL3 */
	ldr	w0, =(SCTLR_EL3_RES1 | SCTLR_I_BIT | SCTLR_SA_BIT)
	msr	sctlr_el3, x0

	/* Custom plat prep_c init */
	bl	z_arm64_el3_plat_prep_c

	/* Set SP_EL1 */
	msr     sp_el1, x24

	b	out
2:
	/*
	 * Initialize hcr_el2 register, fot EL2 trap
	*/
	mov_q	x0,	HCR_HOST_NVHE_FLAGS
	msr		hrc_el2,	x0
	isb

	/**
	 * Initialize EL2 registers to sane values. This should be called early on all
	 * cores that were booted in EL2. Note that everything gets initialised as
	 * if VHE was not evailable. The kernel context will be upgraded to VHE
	 * if possible later on in the boot process
	 * Regs: x0, x1 and x2 are clobbered.
	 */
	__init_el2_sctlr
	__init_el2_timers
	__init_el2_debug
	__init_el2_lor
	__init_el2_stage2
	__init_el2_gicv3
	__init_el2_hstr
	__init_el2_nvhe_idregs
	__init_el2_nvhe_cptr
	__init_el2_nvhe_sve
	__init_el2_fgt
	__init_el2_nvhe_prepare_eret



	/* Disable alignment fault checking */
	mrs	x0, sctlr_el2
	bic	x0, x0, SCTLR_A_BIT
	msr	sctlr_el2, x0

	/* Custom plat prep_c init */
	bl	z_arm64_el2_plat_prep_c

	/* Set SP_EL1 */
	msr     sp_el1, x24

	b	out
1:
	/* Disable alignment fault checking */
	mrs	x0, sctlr_el1
	bic	x0, x0, SCTLR_A_BIT
	msr	sctlr_el1, x0

	/* Custom plat prep_c init */
	bl	z_arm64_el1_plat_prep_c

	/* Set SP_EL1. We cannot use sp_el1 at EL1 */
	msr     SPSel, #1
	mov     sp, x24
out:
	isb

	/* Select SP_EL0 */
	msr	SPSel, #0

	/* Initialize stack */
	mov	sp, x24

	ret	x23

/*
 * Reset vector
 *
 * Ran when the system comes out of reset. The processor is in thread mode with
 * privileged level. At this point, neither SP_EL0 nor SP_ELx point to a valid
 * area in SRAM.
 */

GTEXT(__reset)
SECTION_SUBSEC_FUNC(TEXT,_reset_section,__reset)

GTEXT(__start)
SECTION_SUBSEC_FUNC(TEXT,_reset_section,__start)
	/* Mask all exceptions */
	msr	DAIFSet, #0xf

#if CONFIG_MP_NUM_CPUS > 1

	ldr	x0, =arm64_cpu_boot_params
	get_cpu_id x1
	ldr	x2, [x0, #BOOT_PARAM_MPID_OFFSET]
	cmp	x2, #-1
	beq	primary_core

	/* loop until our turn comes */
1:	dmb	ld
	ldr	x2, [x0, #BOOT_PARAM_MPID_OFFSET]
	cmp	x1, x2
	bne	1b

	/* we can now load our stack pointer value and move on */
	ldr	x24, [x0, #BOOT_PARAM_SP_OFFSET]
	ldr	x25, =z_arm64_secondary_prep_c
	b	2f

primary_core:
	/* advertise ourself */
	str	x1, [x0, #BOOT_PARAM_MPID_OFFSET]
#endif
	/* load primary stack and entry point */
	ldr	x24, =(z_interrupt_stacks + CONFIG_ISR_STACK_SIZE)
	ldr	x25, =z_arm64_prep_c
2:
	/* Prepare for calling C code */
	bl	__reset_prep_c

	/* Platform hook for highest EL */
	bl	z_arm64_el_highest_init

switch_el:
	switch_el x0, 3f, 2f, 1f
3:
	/* EL3 init */
	bl	z_arm64_el3_init

	/* Get next EL */
	adr	x0, switch_el
	bl	z_arm64_el3_get_next_el
	eret

2:
	/* EL2 init */
	bl	z_arm64_el2_init

	/* Move to EL1 with all exceptions masked */
	mov_imm	x0, (SPSR_DAIF_MASK | SPSR_MODE_EL1T)
	msr	spsr_el2, x0

	adr	x0, 1f
	msr	elr_el2, x0
	eret

1:
	/* EL1 init */
	bl	z_arm64_el1_init

	/* Enable SError interrupts */
	msr	DAIFClr, #(DAIFCLR_ABT_BIT)
	isb

	ret	x25  /* either z_arm64_prep_c or z_arm64_secondary_prep_c */
