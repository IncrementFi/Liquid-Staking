import sFlowToken from 0xe3e282271a7c714e
import sFlowStakingManagerV3 from 0xe3e282271a7c714e
import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61

// https://flowscan.org/transaction/16e126999f9be7aa351cdce8f147995675feb5bd31ae4ca1ec065d49ac3abe0f

transaction(amount: UFix64) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault
    let account: AuthAccount
    let isInitialized: Bool

    prepare(signer: AuthAccount) {
    self.account = signer

        if self.account.getCapability(/public/sFlowTokenReceiver).borrow<&{FungibleToken.Receiver}>() == nil {
            self.isInitialized = false
        } else {
            self.isInitialized = true
        }

        // Get a reference to the signer''s stored vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)?? panic("Could not borrow reference to the owner''s Vault!")

        // Withdraw tokens from the signer''s stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        if self.isInitialized == false {
            // setup account if not setup yet
            self.account.save<@sFlowToken.Vault>(<-sFlowToken.createEmptyVault(), to: /storage/sFlowTokenVault)
            log("Empty Vault stored")
            // Create a public Receiver capability to the Vault
            let ReceiverRef1 = self.account.link<&sFlowToken.Vault{FungibleToken.Receiver}>(/public/sFlowTokenReceiver, target: /storage/sFlowTokenVault)
            // Create a public Balance capability to the Vault
            let BalanceRef = self.account.link<&sFlowToken.Vault{FungibleToken.Balance}>(/public/sFlowTokenBalance, target: /storage/sFlowTokenVault)
            log("References created")   
        }

        // Deposit the withdrawn tokens in the recipient''s receiver
        let sFlowVault <- sFlowStakingManagerV3.stake(from: <-self.sentVault)

        let vaultRef = self.account.borrow<&sFlowToken.Vault>(from: /storage/sFlowTokenVault)?? panic("Could not borrow reference to the owner''s Vault!")
        vaultRef.deposit(from: <- sFlowVault)
    }
}