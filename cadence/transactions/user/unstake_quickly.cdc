import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(stFlowAmount: UFix64) {
    prepare(userAccount: AuthAccount) {
        let flowVault = userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        var stFlowVault = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)!

        let inVault <- stFlowVault.withdraw(amount: stFlowAmount) as! @stFlowToken.Vault
        
        let outVault <- LiquidStaking.unstakeQuickly(stFlowVault: <-inVault)
        
        flowVault.deposit(from: <-outVault)
    }
}