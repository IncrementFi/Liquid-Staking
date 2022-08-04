import FlowEpoch from "../../contracts/flow/FlowEpoch.cdc"

transaction() {

    prepare(acct: AuthAccount) {
        let heatbeat = acct.borrow<&FlowEpoch.Heartbeat>(from: FlowEpoch.heartbeatStoragePath)!
        heatbeat.endStakingAuction()

        heatbeat.startEpochCommit()

        heatbeat.calculateAndSetRewards()
        heatbeat.endEpoch()
        heatbeat.payRewards();
    }
}