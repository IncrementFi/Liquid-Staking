import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

transaction(nextRewardAmount: UFix64) {

    prepare(acct: AuthAccount) {
        let heatbeat = acct.borrow<&FlowEpoch.Heartbeat>(from: FlowEpoch.heartbeatStoragePath)!
        //
        heatbeat.endStakingAuction()
        //
        heatbeat.startEpochCommit()
        //
        heatbeat.calculateAndSetRewards()
        heatbeat.endEpoch()
        heatbeat.payRewards();


        let adminRef = acct.borrow<&FlowIDTableStaking.Admin>(from: FlowIDTableStaking.StakingAdminStoragePath)
            ?? panic("Could not borrow reference to staking admin")
        
        adminRef.setEpochTokenPayout(nextRewardAmount)
    }
}