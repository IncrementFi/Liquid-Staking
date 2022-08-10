import FungibleToken from "./standard/FungibleToken.cdc"
import LiquidStakingInterfaces from "./LiquidStakingInterfaces.cdc"
import LiquidStakingConfig from "./LiquidStakingConfig.cdc"


pub contract stFlowToken: FungibleToken {

    // Total supply of Flow tokens in existence
    pub var totalSupply: UFix64

    // 
    pub let tokenVaultPath: StoragePath
    pub let tokenProviderPath: PrivatePath
    pub let tokenBalancePath: PublicPath
    pub let tokenReceiverPath: PublicPath
    pub let tokenStakingInfoPath: PublicPath

    pub var liquidStakingAddress: Address
    

    // Event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    // Event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    // Event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

    // Event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)

    // Event that is emitted when a new burner resource is created
    pub event BurnerCreated()

    // TODO
    pub struct StakingInfo {
        pub var latestCommittedBalance: UFix64?
        pub var latestCommittedEpoch: UInt64?
        
        init() {
            self.latestCommittedBalance = nil
            self.latestCommittedEpoch = nil
        }
    }

    pub resource interface StakingVoucher {
        pub var rewardIndex: UFix64?
        pub var latestCommittedBalance: UFix64?
        pub var latestCommittedEpoch: UInt64?

        //pub var stakingInfos: {String: StakingInfo}
    }
    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, StakingVoucher {

        // holds the balance of a users tokens
        pub var balance: UFix64

        //pub var stakingInfos: {String: StakingInfo}

        pub var latestCommittedBalance: UFix64?
        pub var latestCommittedEpoch: UInt64?
        pub var rewardIndex: UFix64?

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
            self.latestCommittedBalance = nil
            self.latestCommittedEpoch = nil
            self.rewardIndex = nil
        }
        
        access(contract) fun initStakingVoucherVault() {
            self.latestCommittedBalance = self.balance
            self.latestCommittedEpoch = stFlowToken.getLiquidStakingPublicRef().getEpochToCommitStaking()
            self.rewardIndex = 0.0
        }

        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @stFlowToken.Vault

            // TODO 传入的这个vault的stakingInfo也需要update

            // TODO
            self.mergeVault(vault: &vault as &stFlowToken.Vault)

            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        access(self) fun mergeVault(vault: &stFlowToken.Vault) {
            self.balance = self.balance + vault.balance
            
            // update
            self.updateVault()

            // merge
            if vault.latestCommittedEpoch != nil {
                if self.latestCommittedEpoch == nil {
                    self.latestCommittedEpoch = vault.latestCommittedEpoch
                    self.latestCommittedBalance = vault.latestCommittedBalance
                } else {
                    assert(self.latestCommittedEpoch == vault.latestCommittedEpoch, message: "Committed Epoch have to be the same to merge")
                    self.latestCommittedBalance = self.latestCommittedBalance! + vault.latestCommittedBalance!
                }
            }
        }

        pub fun updateVault() {
            
            if (self.latestCommittedEpoch != nil) {

                let liquidStakingRef = stFlowToken.getLiquidStakingPublicRef()

                let currentEpoch = liquidStakingRef.getCurrentEpoch()

                if (currentEpoch > self.latestCommittedEpoch!) {
                    // TODO 这些老的committed会被锁住，重新计算

                    let commitLockedEpoch = self.latestCommittedEpoch! + 1
                    let lockedRewardIndex = liquidStakingRef.getRewardIndex(epoch: commitLockedEpoch)

                    if self.rewardIndex == nil {
                        self.rewardIndex = lockedRewardIndex
                    } else {
                        self.rewardIndex = (self.rewardIndex! * (self.balance - self.latestCommittedBalance!) + lockedRewardIndex * self.latestCommittedBalance! ) / self.balance
                    }

                    self.latestCommittedEpoch = nil
                    self.latestCommittedBalance = nil
                }
            }
        }

        destroy() {
            // TODO 如果有一些利息没有获取，不让destroy
            stFlowToken.totalSupply = stFlowToken.totalSupply - self.balance
        }
    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createEmptyVault(): @FungibleToken.Vault {
        return <-create Vault(balance: 0.0)
    }

    pub fun getLiquidStakingPublicRef(): &{LiquidStakingInterfaces.LiquidStakingPublic} {
        let liquidStakingRef = getAccount(self.liquidStakingAddress).getCapability(LiquidStakingConfig.LiquidStakingPublicPath).borrow<&{LiquidStakingInterfaces.LiquidStakingPublic}>()!
        return liquidStakingRef
    }

    pub resource Administrator {
        // createNewMinter
        //
        // Function that creates and returns a new minter resource
        //
        pub fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        // createNewBurner
        //
        // Function that creates and returns a new burner resource
        //
        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    // Minter
    //
    // Resource object that token admin accounts can hold to mint new tokens.
    //
    pub resource Minter {

        // the amount of tokens that the minter is allowed to mint
        pub var allowedAmount: UFix64

        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun mintTokens(amount: UFix64): @stFlowToken.Vault {
            pre {
                amount > UFix64(0): "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            stFlowToken.totalSupply = stFlowToken.totalSupply + amount
            if (self.allowedAmount != UFix64.max) {
                self.allowedAmount = self.allowedAmount - amount
            }

            let stFlowVault <-create Vault(balance: amount)
            // Init staking params on new minted stFlow vault
            stFlowVault.initStakingVoucherVault()

            emit TokensMinted(amount: amount)
            
            return <-stFlowVault
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }
    
    // Burner
    //
    // Resource object that token admin accounts can hold to burn tokens.
    //
    pub resource Burner {

        // burnTokens
        //
        // Function that destroys a Vault instance, effectively burning the tokens.
        //
        // Note: the burned tokens are automatically subtracted from the 
        // total supply in the Vault destructor.
        //
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault <- from as! @stFlowToken.Vault
            let amount = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    init() {
        self.totalSupply = 0.0

        self.tokenVaultPath = /storage/stFlowTokenVault
        self.tokenProviderPath = /private/stFlowTokenProvider
        self.tokenReceiverPath = /public/stFlowTokenReceiver
        self.tokenBalancePath = /public/stFlowTokenBalance
        self.tokenStakingInfoPath = /public/stFlowTokenStakingInfo

        self.liquidStakingAddress = stFlowToken.account.address
        
        // Create the Vault with the total supply of tokens and save it in storage
        //
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.tokenVaultPath)

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        //
        self.account.link<&stFlowToken.Vault{FungibleToken.Receiver}>(self.tokenReceiverPath, target: self.tokenVaultPath)

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        //
        self.account.link<&stFlowToken.Vault{FungibleToken.Balance}>(self.tokenBalancePath, target: self.tokenVaultPath)

        let admin <- create Administrator()
        self.account.save(<-admin, to: /storage/stFlowTokenAdmin)

        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}