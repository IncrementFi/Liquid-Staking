import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"

transaction() {
    prepare(account: AuthAccount) {
        let delegator <- FlowIDTableStaking.registerNewDelegator(nodeID: "node-3-1")

        let flowVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!

        //delegator.delegateNewTokens(from: <- flowVault.withdraw(amount: 1.0))
        
        account.save(<-delegator, to: /storage/delegator1)
    }
}