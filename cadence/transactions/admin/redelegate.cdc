import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(nodeID: String, delegatorID: UInt32, redelegateAmount: UFix64) {
    prepare(nodeMgrAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)
            ?? panic("cannot borrow reference to Liquid Staking Admin")
        adminRef.redelegate(nodeID: nodeID, delegatorID: delegatorID, amount: redelegateAmount)
    }
}