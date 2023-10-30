import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction() {
    prepare(nodeMgrAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)
            ?? panic("cannot borrow reference to Liquid Staking Admin")

        let bot <- adminRef.createStrategy()

        nodeMgrAcct.save(<-bot, to: DelegatorManager.delegationStrategyPath)
    }
}