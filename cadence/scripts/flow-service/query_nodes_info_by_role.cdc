import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"


pub struct NodeInfo {
    pub let id: String
    pub let role: UInt8
    pub let networkingAddress: String
    pub let networkingKey: String
    pub let stakingKey: String
        

    pub let tokensStaked: UFix64
    pub let tokensCommitted: UFix64
    pub let tokensUnstaking: UFix64
    pub let tokensUnstaked: UFix64
    //pub let tokensRewarded: UFix64
//
    ///// list of delegator IDs for this node operator
    pub let delegatorIDCounter: UInt32
    pub var delegatorStaked: UFix64
    //pub let tokensRequestedToUnstake: UFix64
    //pub let initialWeight: UInt64
    init(_ nodeInfo:FlowIDTableStaking.NodeInfo) {
        self.id = nodeInfo.id
        self.role = nodeInfo.role
        self.networkingAddress = nodeInfo.networkingAddress
        self.networkingKey = nodeInfo.networkingKey
        self.stakingKey = nodeInfo.stakingKey
        
        self.tokensStaked = nodeInfo.tokensStaked
        self.tokensUnstaking = nodeInfo.tokensUnstaking
        self.tokensCommitted = nodeInfo.tokensCommitted
        self.tokensUnstaked = nodeInfo.tokensUnstaked
        self.delegatorIDCounter = nodeInfo.delegatorIDCounter
        self.delegatorStaked = 0.0
        if self.networkingAddress != "flow-consensus.portto.io:3569" {
            self.delegatorStaked = nodeInfo.totalStakedWithDelegators() - self.tokensStaked
        } else {
            self.delegatorStaked = 24748918.24727006
        }

        //self.tokensRewarded = nodeInfo.tokensRewarded
    }
}

pub fun main(role: UInt8): AnyStruct {
    // current nodes can be staked
    let nodeIds = FlowIDTableStaking.getStakedNodeIDs();
    let nodeInfos: {Int: NodeInfo} = {}
    var index = 0;
    var totalNodeStaked = 0.0
    var totalNodeDelegated = 0.0
    for nodeId in nodeIds {
        let nodeInfo = FlowIDTableStaking.NodeInfo(nodeID: nodeId)
        if nodeInfo.role != role && role != 0 {
            continue
        }
        if nodeInfo.role == 5 {
            continue
        }
        
        nodeInfos[index] = NodeInfo(nodeInfo)
        totalNodeStaked = totalNodeStaked + nodeInfos[index]!.tokensStaked
        totalNodeDelegated = totalNodeDelegated + nodeInfos[index]!.delegatorStaked
        index = index + 1
    }
    return [nodeInfos, totalNodeStaked, totalNodeDelegated, totalNodeDelegated+totalNodeStaked]
}
 