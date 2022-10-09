import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(nodeID: String, delegatorID: UInt32, redelegateAmount: UFix64) {
    prepare(nodeMgrAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        adminRef.redelegate(nodeID: nodeID, delegatorID: delegatorID, amount: redelegateAmount)
    }
}