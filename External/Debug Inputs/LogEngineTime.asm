################################################################################
# Address: 0x801a4dec
################################################################################

.include "Common/Common.s"
.include "Online/Online.s" # Required for logf buffer, should fix that
.include "./DebugInputs.s"

# Check if VS Mode
getMinorMajor r3
cmpwi r3, 0x0202
bne EXIT

loadGlobalFrame r3
cmpwi r3, 0
ble EXIT

.set REG_DIB, 31
.set REG_INTERRUPTS, 30
.set REG_DIFF_US, 29
.set REG_KEY, 28
.set REG_DEVELOP_TEXT, 27

backup

branchl r12, OSDisableInterrupts
mr REG_INTERRUPTS, r3

# Fetch DIB
computeBranchTargetAddress r3, INJ_InitDebugInputs
lwz REG_DIB, 8+0(r3)

# Check if DIB is ready (poll has happened)
lbz r3, DIB_IS_READY(REG_DIB)
cmpwi r3, 0
beq RESTORE_AND_EXIT

# Fetch key from controller input
loadwz r7, 0x804c1fac
rlwinm REG_KEY, r7, 0, 0xF

# Calculate time diff
calcDiffTicksToUs REG_DIB, REG_KEY
mr REG_DIFF_US, r3

# Log
mr r7, REG_DIFF_US
mr r6, REG_KEY
loadGlobalFrame r5
logf LOG_LEVEL_WARN, "ENGINE %u 0x%X %u" # Label Frame TimeUs

# Adjust develop text BG color
lwz r3, DIB_DEVELOP_TEXT_ADDR(REG_DIB)
stb REG_KEY, BKP_FREE_SPACE_OFFSET+0(sp)
stb REG_KEY, BKP_FREE_SPACE_OFFSET+1(sp)
stb REG_KEY, BKP_FREE_SPACE_OFFSET+2(sp)
lwz r4, BKP_FREE_SPACE_OFFSET(sp)
rlwinm r4, r4, 4, 0xFFFFF000
ori r4, r4, 0xFF
stw r4, BKP_FREE_SPACE_OFFSET(sp)
addi r4, sp, BKP_FREE_SPACE_OFFSET
branchl r12, 0x80302b90 # DevelopText_StoreBGColor

# Restore interrupts
mr r3, REG_INTERRUPTS
branchl r12, OSRestoreInterrupts

RESTORE_AND_EXIT:
restore

EXIT:
lwz r0, -0x6C98(r13)