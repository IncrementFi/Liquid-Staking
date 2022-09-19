import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"
import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import FlowStakingCollection from "../../contracts/standard/emulator/FlowStakingCollection.cdc"

import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import LiquidStakingConfig from "../../contracts/LiquidStakingConfig.cdc"
import DelegatorManager from "../../contracts/DelegatorManager.cdc"

pub fun main(userAddr: Address?): {String: AnyStruct} {
    let currentSnapshot = DelegatorManager.borrowEpochSnapshot(at: DelegatorManager.quoteEpochCounter)
    let currentBlockView = getCurrentBlock().view
    let currentEpochMetadata = FlowEpoch.getEpochMetadata(DelegatorManager.quoteEpochCounter)!
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
        let voucherCollectionRef = getAccount(userAddr!).getCapability<&{LiquidStaking.UnstakingVoucherCollectionPublic}>(LiquidStaking.UnstakingVoucherCollectionPublicPath).borrow()
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

        "stFlowFlow": currentSnapshot.scaledQuoteStFlowFlow,
        "FlowStFlow": currentSnapshot.scaledQuoteFlowStFlow,
        
        "TotalStaked": DelegatorManager.getTotalValidStakingAmount(),
        "APR": FlowIDTableStaking.getEpochTokenPayout() / FlowIDTableStaking.getTotalStaked() / 7.0 * 365.0 * (1.0 - FlowIDTableStaking.getRewardCutPercentage()),  // TODO: use APY

        "EpochMetadata": {
            "StartView": showEpochMetadata.startView,
            "StartTimestamp": currentSnapshot.quoteEpochStartTimestamp,
            "EndView": showEpochMetadata.endView,
            "CurrentView": currentBlockView,  // TODO 这里需要加上window
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
