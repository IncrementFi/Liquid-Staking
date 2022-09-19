import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(requestUnstakeAmount: UFix64, uuid: UInt64) {
    prepare(botAcct: AuthAccount) {
        log("---------> request unstake amount ".concat(requestUnstakeAmount.toString()))
        let bot = botAcct.borrow<&DelegatorManager.DelegationStrategy>(from: /storage/liquidStakingBot)!

        bot.processUnstakeRequest(requestUnstakeAmount: requestUnstakeAmount, delegatorUUID: uuid)
    }
}
