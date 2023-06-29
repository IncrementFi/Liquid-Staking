import DelegatorManager from "../../contracts/DelegatorManager.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"

transaction(initialCommitment: UFix64) {
    prepare(nodeMgrAcct: AuthAccount) {
        let vaultRef = nodeMgrAcct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("cannot borrow reference to Flow Vault")
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        let ids: {String: UFix64} = {
            "55069e7e8926867bee8094bd31786f8f6b65c8c3bde468ae2275f33dc1245dc1": 1.0,  // HashQuark
            "093132ae6b090b3cf3b14d5da282e8a9cc6e5158342a83354c4fd27d5263416e": 1.0,  // Versus
            "8f8d77ba98d1606b19fce8f6d35908bfc29ea171c02879162f6755c05e0ca1ee": 1.0   // Blockchain at Berkeley
        }
        adminRef.initApprovedNodeIDList(nodeIDs: ids, defaultNodeIDToStake: "55069e7e8926867bee8094bd31786f8f6b65c8c3bde468ae2275f33dc1245dc1")

        adminRef.registerApprovedDelegator(nodeID: "55069e7e8926867bee8094bd31786f8f6b65c8c3bde468ae2275f33dc1245dc1", initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
        adminRef.registerApprovedDelegator(nodeID: "093132ae6b090b3cf3b14d5da282e8a9cc6e5158342a83354c4fd27d5263416e", initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
        adminRef.registerApprovedDelegator(nodeID: "8f8d77ba98d1606b19fce8f6d35908bfc29ea171c02879162f6755c05e0ca1ee", initialCommit: <- vaultRef.withdraw(amount: initialCommitment))
    }
}