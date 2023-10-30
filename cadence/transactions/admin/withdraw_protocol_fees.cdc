import DelegatorManager from "../../contracts/DelegatorManager.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(feeTo: Address) {
    prepare(admin: AuthAccount) {
        let flowReceiverRef = getAccount(feeTo).getCapability(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>()
            ?? panic("cannot borrow receiver reference to the recipient's Vault")
        let adminRef = admin.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)
            ?? panic("cannot borrow reference to Liquid Staking Admin")
        let protocolFeeVault <- adminRef.borrowProtocolFeeVault().withdraw(amount: DelegatorManager.getProtocolFeeBalance())
        flowReceiverRef.deposit(from: <-protocolFeeVault)
    }
}