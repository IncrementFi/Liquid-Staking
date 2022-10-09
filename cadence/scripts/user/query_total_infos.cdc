import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"
import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import FlowStakingCollection from "../../contracts/standard/emulator/FlowStakingCollection.cdc"

import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import LiquidStakingConfig from "../../contracts/LiquidStakingConfig.cdc"
import DelegatorManager from "../../contracts/DelegatorManager.cdc"

pub fun main(userAddr: Address?): {String: AnyStruct} {
    let currentProtocolSnapshot = DelegatorManager.borrowCurrentQuoteEpochSnapshot()
    let currentBlockView = getCurrentBlock().view
    // Chain-referenced EpochMetadata
    let currentEpochMetadata = FlowEpoch.getEpochMetadata(FlowEpoch.currentEpochCounter)!
    // Protocol-referenced EpochMetadata
    let showEpochMetadata = FlowEpoch.getEpochMetadata(DelegatorManager.quoteEpochCounter)!

    var unlockEpoch = FlowEpoch.currentEpochCounter + 2
    if FlowIDTableStaking.stakingEnabled() {
        if currentBlockView + LiquidStakingConfig.windowSizeBeforeStakingEnd >= currentEpochMetadata.stakingEndView {
            unlockEpoch = FlowEpoch.currentEpochCounter + 3
        }
    } else {
        unlockEpoch = FlowEpoch.currentEpochCounter + 3
    }

    // voucher
    var voucherInfos: [AnyStruct]? = nil
    if userAddr != nil {
        let voucherCollectionRef = getAccount(userAddr!).getCapability<&{LiquidStaking.WithdrawVoucherCollectionPublic}>(LiquidStaking.WithdrawVoucherCollectionPublicPath).borrow()
        if voucherCollectionRef != nil {
            voucherInfos = voucherCollectionRef!.getVoucherInfos()
        }
    }

    // migrate info
    var lockedTokensUsed = 0.0
    var unlockedTokensUsed = 0.0
    var migratedInfos: [AnyStruct] = []
    if userAddr != nil {
        let stakingCollectionRef = getAccount(userAddr!).getCapability<&{FlowStakingCollection.StakingCollectionPublic}>(FlowStakingCollection.StakingCollectionPublicPath).borrow()
        if stakingCollectionRef != nil {
            migratedInfos = stakingCollectionRef!.getAllDelegatorInfo()
            lockedTokensUsed = stakingCollectionRef!.lockedTokensUsed
            unlockedTokensUsed = stakingCollectionRef!.unlockedTokensUsed
        }
    }

    return {
        "CurrentEpoch": DelegatorManager.quoteEpochCounter,
        "CurrentUnstakeEpoch": unlockEpoch,

        "stFlowFlow": currentProtocolSnapshot.scaledQuoteStFlowFlow,
        "FlowStFlow": currentProtocolSnapshot.scaledQuoteFlowStFlow,

        "TotalStaked": DelegatorManager.getTotalValidStakingAmount(),
        "APR": FlowIDTableStaking.getEpochTokenPayout() / FlowIDTableStaking.getTotalStaked() / 7.0 * 365.0 * (1.0 - FlowIDTableStaking.getRewardCutPercentage()),

        "EpochMetadata": {
            "StartView": showEpochMetadata.startView,
            "StartTimestamp": currentProtocolSnapshot.quoteEpochStartTimestamp,
            "EndView": showEpochMetadata.endView,
            "CurrentView": currentBlockView,
            "CurrentTimestamp": getCurrentBlock().timestamp,
            "StakingEndView": showEpochMetadata.stakingEndView
        },

        "User": {
            "UnstakingVouchers": voucherInfos,
            "MigratedInfos": {
                "lockedTokensUsed": lockedTokensUsed,
                "unlockedTokensUsed": unlockedTokensUsed,
                "migratedInfos": migratedInfos
            }
        },

        "MinStakingAmount": LiquidStakingConfig.minStakingAmount
    }
}