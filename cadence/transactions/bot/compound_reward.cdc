import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction() {
    prepare(botAcct: AuthAccount) {
        
        let bot = botAcct.borrow<&DelegatorManager.DelegationStrategy>(from: DelegatorManager.delegationStrategyPath)!

        bot.compoundRewards()
    }
}