import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(stFlowAmount: UFix64) {
    prepare(userAccount: AuthAccount) {
        var stFlowVault = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)!
        let inVault <- stFlowVault.withdraw(amount: stFlowAmount) as! @stFlowToken.Vault
        
        let voucher <- LiquidStaking.unstakeSlowly(stFlowVault: <-inVault)
        log("--> unstake slowly stFlow ".concat(stFlowAmount.toString()))
        log("--> could get Flow in the future: ".concat(voucher.flowAmount.toString()))

        var voucherCollectionRef = userAccount.borrow<&LiquidStaking.UnstakingVoucherCollection>(from: LiquidStaking.UnstakingVoucherCollectionPath)
        if voucherCollectionRef == nil {
            destroy <- userAccount.load<@AnyResource>(from: LiquidStaking.UnstakingVoucherCollectionPath)
            userAccount.unlink(LiquidStaking.UnstakingVoucherCollectionPublicPath)

            userAccount.save(<-LiquidStaking.createEmptyUnstakingVoucherCollection(), to: LiquidStaking.UnstakingVoucherCollectionPath)
            userAccount.link<&{LiquidStaking.UnstakingVoucherCollectionPublic}>(LiquidStaking.UnstakingVoucherCollectionPublicPath, target: LiquidStaking.UnstakingVoucherCollectionPath)
            voucherCollectionRef = userAccount.borrow<&LiquidStaking.UnstakingVoucherCollection>(from: LiquidStaking.UnstakingVoucherCollectionPath)
        }
        voucherCollectionRef!.deposit(voucher: <-voucher)
    }
}