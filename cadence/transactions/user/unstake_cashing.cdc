import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"

transaction(uuid: UInt64) {
    prepare(userAccount: AuthAccount) {
        let voucherCollection = userAccount.borrow<&LiquidStaking.WithdrawVoucherCollection>(from: LiquidStaking.WithdrawVoucherCollectionPath)
            ?? panic("cannot borrow reference to WithdrawVoucherCollection")
        let voucher <-voucherCollection.withdraw(uuid: uuid)
        let flowVault <- LiquidStaking.cashoutWithdrawVoucher(voucher: <-voucher)

        userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!.deposit(from: <-flowVault)
    }
}