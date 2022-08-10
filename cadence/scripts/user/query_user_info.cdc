import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import LiquidStaking from "../../contracts/LiquidStaking.cdc"

pub fun main(userAddr: Address): {String: AnyStruct} {
    
    let flowBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance).borrow()!.balance
    let stFlowBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/stFlowTokenBalance).borrow()!.balance

    let stFlowInfo = getAccount(userAddr).getCapability<&{stFlowToken.StakingVoucher}>(/public/stFlowTokenStakingInfo).borrow()!

    //let usdcBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/USDCVaultBalance).borrow()!.balance
    return {
        "Flow": flowBalance,
        "stFlow": stFlowBalance,
        "stFlowInfo": stFlowInfo
    }
}