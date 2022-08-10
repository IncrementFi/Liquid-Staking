import FlowEpoch from "../../contracts/flow/FlowEpoch.cdc"
//import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"
pub fun main(): AnyStruct {
    let curEpochCounter = FlowEpoch.currentEpochCounter
    let curEpochPhase = FlowEpoch.currentEpochPhase
    let nexEpochCounter = FlowEpoch.proposedEpochCounter()

    let epochData0 = FlowEpoch.getEpochMetadata(0)
    let epochData1 = FlowEpoch.getEpochMetadata(1)

    return {
        "cur epoch counter": curEpochCounter, 
        "nxt epoch counter": nexEpochCounter,
        //"cur epoch data": epochData0,
        //"nxt epoch data": epochData1,
        "block view": getCurrentBlock().view,
        "state": curEpochPhase
        //"cut": FlowIDTableStaking.getRewardCutPercentage()
    }
}