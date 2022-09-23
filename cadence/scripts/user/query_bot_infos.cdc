import DelegatorManager from "../../contracts/DelegatorManager.cdc"
import LiquidStakingConfig from "../../contracts/LiquidStakingConfig.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"
import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"

pub fun main(): AnyStruct {
    return {
        "StakingEnable": FlowIDTableStaking.stakingEnabled(),
        "QuoteEpoch": DelegatorManager.quoteEpochCounter,
        "FlowEpoch": FlowEpoch.currentEpochCounter,
        "DelegatorLength": DelegatorManager.getDelegatorsLength(),
        "UnprocessedUnstakeRequests": DelegatorManager.requestedToUnstake,
        "WindowSizeBeforeStakingEnd": LiquidStakingConfig.windowSizeBeforeStakingEnd,
        "CurrentView": getCurrentBlock().view,
        "DefaultNodeID": DelegatorManager.defaultNodeIDToStake,
        "DefaultDelegatorCommitted": DelegatorManager.getApprovedDelegatorInfoByNodeID(nodeID: DelegatorManager.defaultNodeIDToStake).tokensCommitted,
        "TotalCommitted": DelegatorManager.borrowCurrentEpochSnapshot().allDelegatorCommitted
    }
}