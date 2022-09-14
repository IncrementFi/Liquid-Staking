import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import FlowStakingCollection from "../../contracts/standard/emulator/FlowStakingCollection.cdc"

pub fun main(userAddr: Address): {String: AnyStruct} {
    
    let flowBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance).borrow()!.balance
    let stFlowBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/stFlowTokenBalance).borrow()!.balance

    let voucherCollectionRef = getAccount(userAddr).getCapability<&{LiquidStaking.UnstakingVoucherCollectionPublic}>(LiquidStaking.UnstakingVoucherCollectionPublicPath).borrow()
    var voucherInfos: [AnyStruct]? = nil
    if voucherCollectionRef != nil {
        voucherInfos = voucherCollectionRef!.getVoucherInfos()
    }

    var lockedTokensUsed = 0.0
    var unlockedTokensUsed = 0.0
    var migratedInfos: [AnyStruct]? = nil
    let stakingCollectionRef = getAccount(userAddr).getCapability<&{FlowStakingCollection.StakingCollectionPublic}>(FlowStakingCollection.StakingCollectionPublicPath).borrow()
    if stakingCollectionRef != nil {
        migratedInfos = stakingCollectionRef!.getAllDelegatorInfo()
        lockedTokensUsed = stakingCollectionRef!.lockedTokensUsed
        unlockedTokensUsed = stakingCollectionRef!.unlockedTokensUsed
    }

    //let usdcBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/USDCVaultBalance).borrow()!.balance
    return {
        "Flow": flowBalance,
        "stFlow": stFlowBalance,
        "UnstakingVouchers": voucherInfos,
        "MigratedInfos": {
            "lockedTokensUsed": lockedTokensUsed,
            "unlockedTokensUsed": unlockedTokensUsed,
            "migratedInfos": migratedInfos
        }
    }
}