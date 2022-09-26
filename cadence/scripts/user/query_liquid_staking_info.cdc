import stFlowToken from "../../contracts/stFlowToken.cdc"
import DelegatorManager from "../../contracts/DelegatorManager.cdc"

pub fun main(): {String: AnyStruct} {
    let currentSnapshot = DelegatorManager.borrowCurrentQuoteEpochSnapshot()
    
    return {
        "stFlow total supply": stFlowToken.totalSupply,
        "Unprocessed unstake request": DelegatorManager.requestedToUnstake,
        "Protocol fees": DelegatorManager.getProtocolFeeBalance(),
        "Unstaked vault": DelegatorManager.getTotalUnstakedVaultBalance(),
        "snapshot": currentSnapshot
    }
}