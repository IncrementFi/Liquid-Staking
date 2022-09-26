import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(requestUnstakeAmount: UFix64, uuid: UInt64) {
    prepare(botAcct: AuthAccount) {
        
        let bot = botAcct.borrow<&DelegatorManager.DelegationStrategy>(from: DelegatorManager.delegationStrategyPath)!

        bot.processUnstakeRequest(requestUnstakeAmount: requestUnstakeAmount, delegatorUUID: uuid)
    }
}
