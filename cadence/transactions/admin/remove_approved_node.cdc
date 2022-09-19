import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(nodeID: String) {
    prepare(nodeMgrAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        adminRef.removeApprovedNodeID(nodeID: nodeID)
    }
}