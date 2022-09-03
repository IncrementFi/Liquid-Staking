import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"

pub fun main(userAddr: Address): {String: AnyStruct} {
    
    let flowBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance).borrow()!.balance
    let stFlowBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/stFlowTokenBalance).borrow()!.balance

    let voucherCollectionRef = getAccount(userAddr).getCapability<&{LiquidStaking.UnstakingVoucherCollectionPublic}>(LiquidStaking.UnstakingVoucherCollectionPublicPath).borrow()
    var voucherInfos: [AnyStruct]? = nil
    if voucherCollectionRef != nil {
        voucherInfos = voucherCollectionRef!.getVoucherInfos()
    }
    //let usdcBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/USDCVaultBalance).borrow()!.balance
    return {
        "Flow": flowBalance,
        "stFlow": stFlowBalance,
        "vouchers": voucherInfos
    }
}