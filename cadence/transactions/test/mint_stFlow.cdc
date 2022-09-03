import stFlowToken from "../../contracts/stFlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(mintAmount: UFix64) {

    prepare(signer: AuthAccount) {
        var stFlowVault = signer.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
        if stFlowVault == nil {
            signer.save(<-stFlowToken.createEmptyVault(), to: stFlowToken.tokenVaultPath)
            signer.link<&stFlowToken.Vault{FungibleToken.Receiver}>(stFlowToken.tokenReceiverPath, target: stFlowToken.tokenVaultPath)
            signer.link<&stFlowToken.Vault{FungibleToken.Balance}>(stFlowToken.tokenBalancePath, target: stFlowToken.tokenVaultPath)
        }
        stFlowVault = signer.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
        stFlowVault!.deposit(from: <-stFlowToken.test_minter.mintTokens(amount: mintAmount))
    }
}
