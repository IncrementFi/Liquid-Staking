import DelegatorManager from "../../contracts/DelegatorManager.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"

transaction(initialCommitment: UFix64) {
    prepare(nodeMgrAcct: AuthAccount) {
        log("---------> node: set approved list")
        let vaultRef = nodeMgrAcct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("cannot borrow reference to Flow Vault")
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        let ids: {String: UFix64} = {
            "node-1-1": 1.0,
            "node-1-2": 1.0,
            "node-1-3": 1.0,
            "node-1-4": 1.0,
            "node-1-5": 1.0
        }
        adminRef.initApprovedNodeIDList(nodeIDs: ids, defaultNodeIDToStake: "node-1-1")

        adminRef.registerApprovedDelegator(nodeID: "node-1-1", initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
        adminRef.registerApprovedDelegator(nodeID: "node-1-2", initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
        adminRef.registerApprovedDelegator(nodeID: "node-1-3", initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
        adminRef.registerApprovedDelegator(nodeID: "node-1-4", initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
        adminRef.registerApprovedDelegator(nodeID: "node-1-5", initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
    }
}