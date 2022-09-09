import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

pub fun main(): AnyStruct {
    // current nodes can be staked
    let stakedNodeIds = FlowIDTableStaking.getStakedNodeIDs();
    let nodeIDs = FlowIDTableStaking.getNodeIDs();
    
    return [nodeIDs.length, stakedNodeIds.length]
}