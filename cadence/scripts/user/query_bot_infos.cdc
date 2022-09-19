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
        "UnprocessedUnstakeRequests": DelegatorManager.reservedRequestedToUnstakeAmount,
        "WindowSizeBeforeStakingEnd": LiquidStakingConfig.windowSizeBeforeStakingEnd,
        "CurrentView": getCurrentBlock().view,
        "ReservedNodeID": DelegatorManager.reservedNodeIDToStake,
        "ReservedCommittedAmount": DelegatorManager.getApprovedDelegatorInfoByNodeID(nodeID: DelegatorManager.reservedNodeIDToStake).tokensCommitted,
        "TotalCommitted": DelegatorManager.borrowQuoteEpochSnapshot().allDelegatorCommitted
    }
}