import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

pub fun main(): AnyStruct {
    let curEpochCounter = FlowEpoch.currentEpochCounter
    let curEpochPhase = FlowEpoch.currentEpochPhase
    let nexEpochCounter = FlowEpoch.proposedEpochCounter()

    let epochData0 = FlowEpoch.getEpochMetadata(0)
    let epochData1 = FlowEpoch.getEpochMetadata(1)

    return {
        "System Totoal stated:": FlowIDTableStaking.getTotalStaked(),
        //"Total delegator tokens:": FlowIDTableStaking.
        "Cur reward:": FlowIDTableStaking.getEpochTokenPayout(),
        "Cur epoch": curEpochCounter, 
        "Cur Block view": getCurrentBlock().view,
        "Cur Block height": getCurrentBlock().height,
        "Epoch State": curEpochPhase,
        "auto paid?": FlowEpoch.automaticRewardsEnabled(),
        "CurrentMetadata": FlowEpoch.getEpochMetadata(curEpochCounter)
    }
}