import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"
import FlowEpoch from "../../contracts/flow/FlowEpoch.cdc"

import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import DelegatorManager from "../../contracts/DelegatorManager.cdc"

pub fun main(userAddr: Address?): {String: AnyStruct} {
    let currentSnapshot = DelegatorManager.borrowEpochSnapshot(at: DelegatorManager.quoteEpochCounter)
    

    var voucherInfos: [AnyStruct]? = nil
    if userAddr != nil {
        let voucherCollectionRef = getAccount(userAddr!).getCapability<&{LiquidStaking.UnstakingVoucherCollectionPublic}>(LiquidStaking.UnstakingVoucherCollectionPublicPath).borrow()
        if voucherCollectionRef != nil {
            // voucherInfos = voucherCollectionRef!.getVoucherInfos()
            voucherInfos = [
                {
                    "uuid": 0,
                    "lockedFlowAmount": 12.123,
                    "unlockEpoch": FlowEpoch.currentEpochCounter + 1
                },
                {
                    "uuid": 1,
                    "lockedFlowAmount": 1241.212,
                    "unlockEpoch": FlowEpoch.currentEpochCounter
                }
            ]
        }
    }
    //let usdcBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/USDCVaultBalance).borrow()!.balance
    return {
        "CurrentEpoch": FlowEpoch.currentEpochCounter,
        "stFlowFlow": 1.0015, //currentSnapshot.quoteStFlowFlow,
        "FlowStFlow": 0.9985, //currentSnapshot.quoteFlowStFlow,
        "FlowUSD": 2.4,

        "UnstakingVouchers": voucherInfos
    }
}