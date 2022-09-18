import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction() {
    prepare(nodeMgrAcct: AuthAccount, botAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        
        let bot <- adminRef.createBot()
        
        botAcct.save(<-bot, to: /storage/liquidStakingBot)
    }
}