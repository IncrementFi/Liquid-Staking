import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(fromNode: String, toNode: String, amount: UFix64) {
    prepare(botAcct: AuthAccount) {
        log("---------> move committed")
        let bot = botAcct.borrow<&DelegatorManager.DelegationStrategy>(from: /storage/liquidStakingBot)!
        
        bot.transferCommittedTokens(fromNodeID: fromNode, toNodeID: toNode, transferAmount: amount)
    }
}