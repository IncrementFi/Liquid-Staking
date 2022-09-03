import FlowEpoch from "../../contracts/flow/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"

pub fun main(): AnyStruct {
    // current nodes can be staked
    let stakedNodeIds = FlowIDTableStaking.getStakedNodeIDs();
    let nodeIDs = FlowIDTableStaking.getNodeIDs();
    
    return [nodeIDs.length, stakedNodeIds.length]
}