import DelegatorManager from "../../contracts/DelegatorManager.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"

transaction(nodeID: String, initialCommitment: UFix64) {
    prepare(nodeMgrAcct: AuthAccount) {
        let vaultRef = nodeMgrAcct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("cannot borrow reference to Flow Vault")
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)
            ?? panic("cannot borrow reference to Liquid Staking Admin")
        adminRef.upsertApprovedNodeID(nodeID: nodeID, weight: 1.0)
        adminRef.registerApprovedDelegator(nodeID: nodeID, initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
    }
}