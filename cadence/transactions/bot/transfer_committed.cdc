import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(fromNode: String, toNode: String, amount: UFix64) {
    prepare(botAcct: AuthAccount) {
        
        let bot = botAcct.borrow<&DelegatorManager.DelegationStrategy>(from: DelegatorManager.delegationStrategyPath)!
        
        bot.transferCommittedTokens(fromNodeID: fromNode, toNodeID: toNode, amount: amount)
    }
}