import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction() {
    prepare(nodeMgrAcct: AuthAccount) {
        log("---------> node: set approved list")
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        
        let bot <- adminRef.createBot()
        
        nodeMgrAcct.save(<-bot, to: /storage/liquidStakingBot)
    }
}