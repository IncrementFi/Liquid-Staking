import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction() {
    prepare(nodeMgrAcct: AuthAccount, botAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!

        let bot <- adminRef.createStrategy()

        botAcct.save(<-bot, to: DelegatorManager.delegationStrategyPath)
    }
}