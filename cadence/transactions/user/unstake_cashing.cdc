import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(uuid: UInt64) {
    prepare(userAccount: AuthAccount) {
        var voucherCollection = userAccount.borrow<&LiquidStaking.WithdrawVoucherCollection>(from: LiquidStaking.WithdrawVoucherCollectionPath)!
        let voucher <-voucherCollection.withdraw(uuid: uuid)

        let flowVault <- LiquidStaking.cashoutWithdrawVoucher(voucher: <-voucher)
        
        userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!.deposit(from: <-flowVault)
    }
}