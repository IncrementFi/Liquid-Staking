import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"

transaction(payout: UFix64) {

    prepare(acct: AuthAccount) {
        // borrow a reference to the admin object
        let adminRef = acct.borrow<&FlowIDTableStaking.Admin>(from: FlowIDTableStaking.StakingAdminStoragePath)
            ?? panic("Could not borrow reference to staking admin")
        
        adminRef.setEpochTokenPayout(payout)
    }
}