import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"
import FlowStakingCollection from "../../contracts/standard/emulator/FlowStakingCollection.cdc"
/// Registers a delegator in the staking collection resource
/// for the specified nodeID and the amount of tokens to commit
transaction(id: String, delegatorID: UInt32, amount: UFix64) {
    
    let stakingCollectionRef: &FlowStakingCollection.StakingCollection

    prepare(account: AuthAccount) {
        self.stakingCollectionRef = account.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath)
            ?? panic("Could not borrow ref to StakingCollection")
    }

    execute {
        self.stakingCollectionRef.stakeNewTokens(nodeID: id, delegatorID: delegatorID, amount: amount)      
    }
}