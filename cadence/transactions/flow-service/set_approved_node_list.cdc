import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"

transaction() {

    prepare(acct: AuthAccount) {
        // borrow a reference to the admin object
        let adminRef = acct.borrow<&FlowIDTableStaking.Admin>(from: FlowIDTableStaking.StakingAdminStoragePath)
            ?? panic("Could not borrow reference to staking admin")
        
        let nodeIDs = [
            "execute-node-1",
            "execute-node-2",
            "collection-node-1"
        ]
        adminRef.setApprovedList(nodeIDs)
    }
}