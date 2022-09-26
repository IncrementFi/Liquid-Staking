import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(stFlowAmount: UFix64) {
    prepare(userAccount: AuthAccount) {
        var stFlowVault = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)!
        let inVault <- stFlowVault.withdraw(amount: stFlowAmount) as! @stFlowToken.Vault
        
        let voucher <- LiquidStaking.unstake(stFlowVault: <-inVault)
        
        var voucherCollectionRef = userAccount.borrow<&LiquidStaking.WithdrawVoucherCollection>(from: LiquidStaking.WithdrawVoucherCollectionPath)
        if voucherCollectionRef == nil {
            destroy <- userAccount.load<@AnyResource>(from: LiquidStaking.WithdrawVoucherCollectionPath)
            userAccount.unlink(LiquidStaking.WithdrawVoucherCollectionPublicPath)

            userAccount.save(<-LiquidStaking.createEmptyWithdrawVoucherCollection(), to: LiquidStaking.WithdrawVoucherCollectionPath)
            userAccount.link<&{LiquidStaking.WithdrawVoucherCollectionPublic}>(LiquidStaking.WithdrawVoucherCollectionPublicPath, target: LiquidStaking.WithdrawVoucherCollectionPath)
            voucherCollectionRef = userAccount.borrow<&LiquidStaking.WithdrawVoucherCollection>(from: LiquidStaking.WithdrawVoucherCollectionPath)
        }
        voucherCollectionRef!.deposit(voucher: <-voucher)
    }
}