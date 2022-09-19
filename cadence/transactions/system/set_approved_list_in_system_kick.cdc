import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

transaction() {

    prepare(acct: AuthAccount) {
        // borrow a reference to the admin object
        let adminRef = acct.borrow<&FlowIDTableStaking.Admin>(from: FlowIDTableStaking.StakingAdminStoragePath)
            ?? panic("Could not borrow reference to staking admin")
        
        let nodeIDs = [
            "node-1-1",
            "node-1-2",
            "node-1-3",
            "node-1-4"
        ]
        adminRef.setApprovedList(nodeIDs)
    }
}