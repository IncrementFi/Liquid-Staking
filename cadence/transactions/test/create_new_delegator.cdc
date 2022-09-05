import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"

transaction(nodeID: String, amount: UFix64) {
    prepare(account: AuthAccount) {
        let delegator <- FlowIDTableStaking.registerNewDelegator(nodeID: nodeID)

        let flowVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!

        delegator.delegateNewTokens(from: <- flowVault.withdraw(amount: amount))
        
        account.save(<-delegator, to: FlowIDTableStaking.DelegatorStoragePath)
    }
}