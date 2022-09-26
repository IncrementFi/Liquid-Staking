import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(uuid: UInt64) {
    prepare(botAcct: AuthAccount) {
        let bot = botAcct.borrow<&DelegatorManager.DelegationStrategy>(from: DelegatorManager.delegationStrategyPath)!

        bot.cleanDelegators(delegatorUUID: uuid)
    }
}