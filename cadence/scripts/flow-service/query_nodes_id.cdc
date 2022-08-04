import FlowEpoch from "../../contracts/flow/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"

pub fun main(): AnyStruct {
    // current nodes can be staked
    let nodeIds = FlowIDTableStaking.getStakedNodeIDs();
    return nodeIds
}