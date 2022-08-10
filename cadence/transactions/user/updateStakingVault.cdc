import stFlowToken from "../../contracts/stFlowToken.cdc"

transaction() {
    prepare(userAccount: AuthAccount) {
        var stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)!
        stFlowVaultRef.updateVault()
    }
}