 import sFlowToken from 0xe3e282271a7c714e
import sFlowStakingManagerV3 from 0xe3e282271a7c714e
import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61
// https://flowscan.org/transaction/cb9ebc9343dd0d9b3d72e73b477188846f3fe37c631acb2a06fe1e19ad57f018
// https://flowscan.org/transaction/67e77cd26f572f1676abf0277b70928b96b927be02fc20c3f05b37fbdd292407/script
transaction(amount: UFix64) {
    
    var account: AuthAccount
    prepare(signer: AuthAccount) {
    self.account = signer
    }

    execute {
        let vaultRef = self.account.borrow<&sFlowToken.Vault>(from: /storage/sFlowTokenVault)
        ?? panic("Could not borrow reference to the owner''s Vault!")
        let sFlowVault <- vaultRef.withdraw(amount: amount)

        // Deposit the withdrawn tokens in the recipient''s receiver
        sFlowStakingManagerV3.unstake(accountAddress: self.account.address, from: <-sFlowVault)
        // sFlowStakingManager.manageCollection()
    }
}