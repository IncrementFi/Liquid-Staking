import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(flowAmount: UFix64) {
    prepare(userAccount: AuthAccount) {
        let flowVault = userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        let inVault <- flowVault.withdraw(amount: flowAmount) as! @FlowToken.Vault
        
        let outVault <- LiquidStaking.stake(flowVault: <-inVault)

        var stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
        if stFlowVaultRef == nil {
            userAccount.save(<- stFlowToken.createEmptyVault(), to: stFlowToken.tokenVaultPath)
            userAccount.link<&stFlowToken.Vault{FungibleToken.Receiver}>(stFlowToken.tokenReceiverPath, target: stFlowToken.tokenVaultPath)
            userAccount.link<&stFlowToken.Vault{FungibleToken.Balance}>(stFlowToken.tokenBalancePath, target: stFlowToken.tokenVaultPath)

            stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
        }

        stFlowVaultRef!.deposit(from: <-outVault)
    }
}