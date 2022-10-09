import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction() {
    prepare(nodeMgrAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!

        let bot <- adminRef.createStrategy()

        nodeMgrAcct.save(<-bot, to: DelegatorManager.delegationStrategyPath)
    }
}