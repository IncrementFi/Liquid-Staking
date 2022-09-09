import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"


pub struct NodeInfo {
    pub let id: String
    pub let role: UInt8
    pub let networkingAddress: String
    pub let networkingKey: String
    pub let stakingKey: String
        

    pub let tokensStaked: UFix64
    //pub let tokensCommitted: UFix64
    //pub let tokensUnstaking: UFix64
    //pub let tokensUnstaked: UFix64
    //pub let tokensRewarded: UFix64
//
    ///// list of delegator IDs for this node operator
    pub let delegatorIDCounter: UInt32
    pub let delegatorStaked: UFix64
    //pub let tokensRequestedToUnstake: UFix64
    //pub let initialWeight: UInt64
    init(_ nodeInfo:FlowIDTableStaking.NodeInfo) {
        self.id = nodeInfo.id
        self.role = nodeInfo.role
        self.networkingAddress = nodeInfo.networkingAddress
        self.networkingKey = nodeInfo.networkingKey
        self.stakingKey = nodeInfo.stakingKey
        
        self.tokensStaked = nodeInfo.tokensStaked
        self.delegatorIDCounter = nodeInfo.delegatorIDCounter
        self.delegatorStaked = nodeInfo.totalStakedWithDelegators() - self.tokensStaked

        //self.tokensRewarded = nodeInfo.tokensRewarded
    }
}

pub fun main(): AnyStruct {
    
    // nodes not in approved list
    let stakedNodeIds = FlowIDTableStaking.getStakedNodeIDs();
    let nodeIds = FlowIDTableStaking.getNodeIDs();
    let nodeInfos: {Int: NodeInfo} = {}
    var index = 0;
    var totalDelegatorStaked = 0.0
    for nodeId in nodeIds {
        if stakedNodeIds.contains(nodeId) {
            //continue
        }
        let nodeInfo = FlowIDTableStaking.NodeInfo(nodeID: nodeId)

        if nodeInfo.tokensStaked == 0.0 {
            continue
        }
        
        nodeInfos[index] = NodeInfo(nodeInfo)
        totalDelegatorStaked = totalDelegatorStaked + nodeInfos[index]!.delegatorStaked
        index = index + 1
    }
    return totalDelegatorStaked
}