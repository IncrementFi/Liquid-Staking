import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowEpoch from "../../contracts/standard/emulator/FlowEpoch.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import DelegatorManager from "../../contracts/DelegatorManager.cdc"

pub fun main(): {String: AnyStruct} {
    let currentSnapshot = DelegatorManager.borrowEpochSnapshot(at: DelegatorManager.quoteEpochCounter)
    
    return {
        "reserved request unstake tokens:": DelegatorManager.reservedRequestedToUnstakeAmount,
        "Reserved Flow": DelegatorManager.getProtocolReservedVaultBalance(),
        "Unstaked vault": DelegatorManager.getTotalUnstakedVaultBalance(),
        "snapshot": currentSnapshot
    }
}