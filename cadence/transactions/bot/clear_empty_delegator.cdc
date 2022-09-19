import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(uuid: UInt64) {
    prepare(botAcct: AuthAccount) {
        let bot = botAcct.borrow<&DelegatorManager.DelegationStrategy>(from: /storage/liquidStakingBot)!

        bot.cleanDelegators(delegatorUUID: uuid)
    }
}