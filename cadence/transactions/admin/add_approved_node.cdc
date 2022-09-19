import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(nodeID: String) {
    prepare(nodeMgrAcct: AuthAccount) {
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        adminRef.upsertApprovedNodeID(nodeID: nodeID, weight: 1.0)
        adminRef.registerNewDelegator(nodeID: nodeID)
    }
}