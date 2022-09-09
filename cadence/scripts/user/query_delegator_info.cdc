import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

pub fun main(nodeID: String, delegatorID: UInt32): FlowIDTableStaking.DelegatorInfo {
    return FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)
}