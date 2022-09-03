import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction() {
    prepare(nodeMgrAcct: AuthAccount) {
        log("---------> node: set approved list")
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        let ids: {String: UFix64} = {
            "node-3-1": 1.0,
            "node-3-2": 1.0,
            "node-1-1": 1.0
        }
        adminRef.setApprovedNodeIDList(nodeIDs: ids, reservedNodeIDToStake: "node-1-1")

        adminRef.registerNewDelegator(nodeID: "node-1-1")
        adminRef.registerNewDelegator(nodeID: "node-3-1")
        adminRef.registerNewDelegator(nodeID: "node-3-2")
    }
}