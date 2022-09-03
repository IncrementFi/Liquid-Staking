import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(voucherIndex: UInt32) {
    prepare(userAccount: AuthAccount) {
        var voucherCollection = userAccount.borrow<&LiquidStaking.UnstakingVoucherCollection>(from: LiquidStaking.UnstakingVoucherCollectionPath)!
        let voucher <-voucherCollection.withdraw(index: voucherIndex)

        let flowVault <- LiquidStaking.cashingUnstakingVoucher(voucher: <-voucher)
        log("--> cashing voucher")
        log("--> get flow: ".concat(flowVault.balance.toString()))

        userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!.deposit(from: <-flowVault)
    }
}