import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import FlowEpoch from "../../contracts/flow/FlowEpoch.cdc"

pub fun main(): {String: AnyStruct} {
    return {
        "currentRealEpoch": FlowEpoch.currentEpochCounter,
        "currentStakingEpoch": LiquidStaking.currentEpoch,
        
        "totalCommitted": LiquidStaking.totalCommitted,
        "totalStaked": LiquidStaking.totalStaked,
        "totalUnstaking": LiquidStaking.totalUnstaking,
        "totalRewarded": LiquidStaking.totalRewarded,
        "totalUnstaked": LiquidStaking.totalUnstaked,
        "totalRequestedToUnstake": LiquidStaking.totalRequestedToUnstake,

        "delegatorInfos": LiquidStaking.nodeDelegatorInfos
    }
}