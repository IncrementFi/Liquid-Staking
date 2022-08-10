import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"

transaction() {

    prepare(acct: AuthAccount) {
        // borrow a reference to the admin object
        let adminRef = acct.borrow<&FlowIDTableStaking.Admin>(from: FlowIDTableStaking.StakingAdminStoragePath)
            ?? panic("Could not borrow reference to staking admin")
        
        let nodeIDs = [
            "node-3-1",
            "node-3-2",
            "node-1-1"
        ]
        adminRef.setApprovedList(nodeIDs)
    }
}