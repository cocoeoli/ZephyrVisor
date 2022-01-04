/*
 * zvm_arm.h
 *
 *  Created on: Jan 4, 2022
 *      Author: xiong
 */

#ifndef ZEPHYR_INCLUDE_ARCH_ARM64_ZVM_ARM_H_
#define ZEPHYR_INCLUDE_ARCH_ARM64_ZVM_ARM_H_

/*
 * This code is for zvm EL2 mode init.
 */

#define HCR_RW		(1 << HCR_RW_SHIFT)


/* Hyp Configuration Register (HCR) bits
 * Decide whether operations are trap to EL2
 */

#define HCR_TID5	(1 << 58)
#define HCR_DCT		(1 << 57)
#define HCR_ATA_SHIFT	56
#define HCR_ATA		(1 << HCR_ATA_SHIFT)
#define HCR_AMVOFFEN	(1 << 51)
#define HCR_FIEN	(1 << 47)
#define HCR_FWB		(1 << 46)
#define HCR_API		(1 << 41)
#define HCR_APK		(1 << 40)
#define HCR_TEA		(1 << 37)
#define HCR_TERR	(1 << 36)
#define HCR_TLOR	(1 << 35)
#define HCR_E2H		(1 << 34)
#define HCR_ID		(1 << 33)
#define HCR_CD		(1 << 32)
#define HCR_RW_SHIFT	31
#define HCR_RW		(1 << HCR_RW_SHIFT)
#define HCR_TRVM	(1 << 30)
#define HCR_HCD		(1 << 29)
#define HCR_TDZ		(1 << 28)
#define HCR_TGE		(1 << 27)
#define HCR_TVM		(1 << 26)
#define HCR_TTLB	(1 << 25)
#define HCR_TPU		(1 << 24)
#define HCR_TPC		(1 << 23) /* HCR_TPCP if FEAT_DPB */
#define HCR_TSW		(1 << 22)
#define HCR_TACR	(1 << 21)
#define HCR_TIDCP	(1 << 20)
#define HCR_TSC		(1 << 19)
#define HCR_TID3	(1 << 18)
#define HCR_TID2	(1 << 17)
#define HCR_TID1	(1 << 16)
#define HCR_TID0	(1 << 15)
#define HCR_TWE		(1 << 14)
#define HCR_TWI		(1 << 13)
#define HCR_DC		(1 << 12)
#define HCR_BSU		(3 << 10)
#define HCR_BSU_IS	(1 << 10)
#define HCR_FB		(1 << 9)
#define HCR_VSE		(1 << 8)
#define HCR_VI		(1 << 7)
#define HCR_VF		(1 << 6)
#define HCR_AMO		(1 << 5)
#define HCR_IMO		(1 << 4)
#define HCR_FMO		(1 << 3)
#define HCR_PTW		(1 << 2)
#define HCR_SWIO	(1 << 1)
#define HCR_VM		(1 << 0)
#define HCR_RES0	((1 << 48) | (1 << 39))


/*
 * The bits in HCR_EL2:
 * TLOR:	Trap LORegion register accesses
 * RW:		64bit by default, can be overridden for 32bit VMs
 * TACR:	Trap ACTLR
 * TSC:		Trap SMC
 * TSW:		Trap cache operations by set/way
 * TWE:		Trap WFE
 * TWI:		Trap WFI
 * TIDCP:	Trap L2CTLR/L2ECTLR
 * BSU_IS:	Upgrade barriers to the inner shareable domain
 * FB:		Force broadcast of all maintenance operations
 * AMO:		Override CPSR.A and enable signaling with VA
 * IMO:		Override CPSR.I and enable signaling with VI
 * FMO:		Override CPSR.F and enable signaling with VF
 * SWIO:	Turn set/way invalidates into set/way clean+invalidate
 * PTW:		Take a stage2 fault if a stage1 walk steps in device memory
 */
#define HCR_GUEST_FLAGS (HCR_TSC | HCR_TSW | HCR_TWE | HCR_TWI | HCR_VM | \
			 HCR_BSU_IS | HCR_FB | HCR_TACR | \
			 HCR_AMO | HCR_SWIO | HCR_TIDCP | HCR_RW | HCR_TLOR | \
			 HCR_FMO | HCR_IMO | HCR_PTW )
#define HCR_VIRT_EXCP_MASK (HCR_VSE | HCR_VI | HCR_VF)
#define HCR_HOST_NVHE_FLAGS (HCR_RW | HCR_API | HCR_APK | HCR_ATA)
#define HCR_HOST_NVHE_PROTECTED_FLAGS (HCR_HOST_NVHE_FLAGS | HCR_TSC)
#define HCR_HOST_VHE_FLAGS (HCR_RW | HCR_TGE | HCR_E2H)



#endif /* ZEPHYR_INCLUDE_ARCH_ARM64_ZVM_ARM_H_ */

