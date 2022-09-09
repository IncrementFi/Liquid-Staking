import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"
import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"

import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import LiquidStakingConfig from "../../contracts/LiquidStakingConfig.cdc"
import DelegatorManager from "../../contracts/DelegatorManager.cdc"

pub fun main(userAddr: Address?): {String: AnyStruct} {
    let currentSnapshot = DelegatorManager.borrowEpochSnapshot(at: DelegatorManager.quoteEpochCounter)
    let currentBlockView = getCurrentBlock().view
    let currentEpochMetadata = FlowEpoch.getEpochMetadata(DelegatorManager.quoteEpochCounter)!
    let showEpochMetadata = FlowEpoch.getEpochMetadata(FlowEpoch.currentEpochCounter)!

    
    var unlockEpoch = FlowEpoch.currentEpochCounter + 2
    if FlowIDTableStaking.stakingEnabled() {
        if currentBlockView + LiquidStakingConfig.windowSizeBeforeStakingEnd >= currentEpochMetadata.stakingEndView {
            unlockEpoch = FlowEpoch.currentEpochCounter + 3
        }
    } else {
        unlockEpoch = FlowEpoch.currentEpochCounter + 3
    }

    var voucherInfos: [AnyStruct]? = nil
    if userAddr != nil {
        let voucherCollectionRef = getAccount(userAddr!).getCapability<&{LiquidStaking.UnstakingVoucherCollectionPublic}>(LiquidStaking.UnstakingVoucherCollectionPublicPath).borrow()
        if voucherCollectionRef != nil {
            // voucherInfos = voucherCollectionRef!.getVoucherInfos()
            voucherInfos = [
                {
                    "uuid": 0,
                    "lockedFlowAmount": 12.123,
                    "unlockEpoch": FlowEpoch.currentEpochCounter + 1
                },
                {
                    "uuid": 1,
                    "lockedFlowAmount": 1241.212,
                    "unlockEpoch": FlowEpoch.currentEpochCounter
                }
            ]
        }
    }
    //let usdcBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/USDCVaultBalance).borrow()!.balance
    return {
        "CurrentEpoch": DelegatorManager.quoteEpochCounter,
        "CurrentUnstakeEpoch": unlockEpoch,

        "stFlowFlow": currentSnapshot.quoteStFlowFlow,
        "FlowStFlow": currentSnapshot.quoteFlowStFlow,
        "FlowUSD": 1.85,

        "TotalStaked": DelegatorManager.getTotalValidStakingAmount(),
        "APR": FlowIDTableStaking.getEpochTokenPayout() / FlowIDTableStaking.getTotalStaked() * FlowIDTableStaking.getRewardCutPercentage(),

        "EpochMetadata": {
            "StartView": showEpochMetadata.startView,
            "StartTimestamp": currentSnapshot.quoteEpochStartTimestamp,
            "EndView": showEpochMetadata.endView,
            "CurrentView": currentBlockView,
            "CurrentTimestamp": getCurrentBlock().timestamp,
            "StakingEndView": showEpochMetadata.stakingEndView
        },

        "User": {
            "UnstakingVouchers": voucherInfos,
            "MigratedInfos": {
                "lockedTokensUsed": 90.0,
                "unlockedTokensUsed": 83.0,
                "migratedInfos": [
                    {
                        "nodeID": "121132",
                        "id": 123,
                        "tokensCommitted": 10.0,
                        "tokensStaked": 10.0,
                        "tokensUnstaking": 10.0,
                        "tokensRewarded": 10.0,
                        "tokensUnstaked": 10.0,
                        "tokensRequestedToUnstake": 10.0
                    }
                ]
            }
        }
    }
}