import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import SwapInterfaces from 0xb78ef7afa52ff906

transaction(flowAmount: UFix64) {
    prepare(userAccount: AuthAccount) {
        let flowVault = userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        let inVault <- flowVault.withdraw(amount: flowAmount) as! @FlowToken.Vault
        var stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
        if stFlowVaultRef == nil {
            userAccount.save(<- stFlowToken.createEmptyVault(), to: stFlowToken.tokenVaultPath)
            userAccount.unlink(stFlowToken.tokenReceiverPath)
            userAccount.unlink(stFlowToken.tokenBalancePath)
            userAccount.link<&stFlowToken.Vault{FungibleToken.Receiver}>(stFlowToken.tokenReceiverPath, target: stFlowToken.tokenVaultPath)
            userAccount.link<&stFlowToken.Vault{FungibleToken.Balance}>(stFlowToken.tokenBalancePath, target: stFlowToken.tokenVaultPath)

            stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
        }
        
        let poolCapV1 = getAccount(0x396c0cda3302d8c5).getCapability<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!
        let poolCapStable = getAccount(0xc353b9d685ec427d).getCapability<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!
        
        let estimatedStakeOut = LiquidStaking.calcStFlowFromFlow(flowAmount: flowAmount)
        let estimatedSwapOutV1 = poolCapV1.getAmountOut(amountIn: flowAmount, tokenInKey: "A.1654653399040a61.FlowToken")
        let estimatedSwapOutStable = poolCapStable.getAmountOut(amountIn: flowAmount, tokenInKey: "A.1654653399040a61.FlowToken")
        let estimatedSwapOut = (estimatedSwapOutStable>estimatedSwapOutV1)? estimatedSwapOutStable:estimatedSwapOutV1
        let estimatedSwapPoolCap = (estimatedSwapOutStable>estimatedSwapOutV1)? poolCapStable:poolCapV1

        if estimatedStakeOut > estimatedSwapOut {
            let outVault <- LiquidStaking.stake(flowVault: <-inVault)
            stFlowVaultRef!.deposit(from: <-outVault)
        } else {
            let outVault <- estimatedSwapPoolCap.swap(vaultIn: <- inVault, exactAmountOut: nil)
            stFlowVaultRef!.deposit(from: <-outVault)
        }
    }
}