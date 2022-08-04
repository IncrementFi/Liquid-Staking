import FlowEpoch from "../../contracts/flow/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"


pub struct NodeInfo {
    pub let id: String
    pub let role: UInt8
    pub let networkingAddress: String
    //pub let tokensStaked: UFix64
    //pub let tokensCommitted: UFix64
    //pub let tokensUnstaking: UFix64
    //pub let tokensUnstaked: UFix64
    //pub let tokensRewarded: UFix64
//
    ///// list of delegator IDs for this node operator
    //pub let delegatorIDCounter: UInt32
    //pub let tokensRequestedToUnstake: UFix64
    //pub let initialWeight: UInt64
    init(_ nodeInfo:FlowIDTableStaking.NodeInfo) {
        self.id = nodeInfo.id
        self.role = nodeInfo.role
        self.networkingAddress = nodeInfo.networkingAddress       
    }
}

pub fun main(): AnyStruct {
    // current nodes can be staked
    let nodeIds = FlowIDTableStaking.getNodeIDs();
    let nodeInfos: {Int: FlowIDTableStaking.NodeInfo} = {}
    var index = 0;
    for nodeId in nodeIds {
        let nodeInfo = FlowIDTableStaking.NodeInfo(nodeID: nodeId)
        if nodeInfo.role > 4 {
            continue
        }

        nodeInfos[index] = nodeInfo // NodeInfo(nodeInfo)
        
        index = index + 1
    }
    return nodeInfos
}