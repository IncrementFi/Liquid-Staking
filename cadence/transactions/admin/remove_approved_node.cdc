import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(nodeID: String) {
    prepare(nodeMgrAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)
            ?? panic("cannot borrow reference to Liquid Staking Admin")
        adminRef.removeApprovedNodeID(nodeID: nodeID)
    }
}