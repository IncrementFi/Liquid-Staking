import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
pub fun main(userAddr: Address): [UFix64] {
    
    let flowBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance).borrow()!.balance
    //let stFlowBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/stFlowTokenBalance).borrow()!.balance
    //let usdcBalance = getAccount(userAddr).getCapability<&{FungibleToken.Balance}>(/public/USDCVaultBalance).borrow()!.balance
    return [flowBalance]
}