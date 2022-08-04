import FungibleToken from "./standard/FungibleToken.cdc"
import FlowIDTableStaking from "./flow/FlowIDTableStaking.cdc"
import FlowEpoch from "./flow/FlowEpoch.cdc"
import stFlowStaking from "./stFlowStaking.cdc"


pub contract stFlowToken: FungibleToken {

    // Total supply of Flow tokens in existence
    pub var totalSupply: UFix64

    // 
    pub let tokenVaultPath: StoragePath
    pub let tokenProviderPath: PrivatePath
    pub let tokenBalancePath: PublicPath
    pub let tokenReceiverPath: PublicPath
    

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

    
    
    pub struct CommittedVaultInfo {
        pub var balance: UFix64
        pub var epochIndex: UInt64
        init(balance: UFix64, epochIndex: UInt64) {
            self.balance = balance
            self.epochIndex = epochIndex
        }
    }

    pub struct StakingInfo {
        // 未被锁定质押，可随时取款的余额
        pub var balanceUnlocked: UFix64
        pub var balanceLocked: UFix64

        pub var rewardAccumulatedUnlocked: UFix64
        pub var rewardAccumulatedLocked: UFix64
        init(_ balanceUnlocked: UFix64, _ balanceLocked: UFix64, _ rewardAccumulatedUnlocked: UFix64, _ rewardAccumulatedLocked: UFix64) {
            self.balanceUnlocked = balanceUnlocked
            self.balanceLocked = balanceLocked
            self.rewardAccumulatedUnlocked = rewardAccumulatedUnlocked
            self.rewardAccumulatedLocked = rewardAccumulatedLocked
        }
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
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        // holds the balance of a users tokens
        pub var balance: UFix64

        pub var stakingInfo: StakingInfo

        //pub var committedInfo: CommittedVaultInfo

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
            self.stakingInfo = StakingInfo(0.0, 0.0, 0.0, 0.0)
        }
        access(contract) fun initStakingInfo(_ stakingInfo: StakingInfo) {
            self.stakingInfo = stakingInfo
        }
        access(contract) fun updateStakingInfo() {

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
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
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

            emit TokensMinted(amount: amount)

            let stFlowVault <-create Vault(balance: amount)
            // 只有新的质押才会产生stFlow，这些新质押是随时可以提取的
            stFlowVault.initStakingInfo(StakingInfo(amount, 0.0, stFlowStaking.rewardAccumulated, 0.0))

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

    init(adminAccount: AuthAccount) {
        self.totalSupply = 0.0

        self.tokenVaultPath = /storage/stFlowTokenVault
        self.tokenReceiverPath = /public/stFlowTokenReceiver
        self.tokenBalancePath = /public/stFlowTokenBalance
        self.tokenProviderPath = /private/stFlowTokenProvider
        // Create the Vault with the total supply of tokens and save it in storage
        //
        let vault <- create Vault(balance: self.totalSupply)
        adminAccount.save(<-vault, to: self.tokenVaultPath)

        // Create a public capability to the stored Vault that only exposes
        // the `deposit` method through the `Receiver` interface
        //
        adminAccount.link<&stFlowToken.Vault{FungibleToken.Receiver}>(self.tokenReceiverPath, target: self.tokenVaultPath)

        // Create a public capability to the stored Vault that only exposes
        // the `balance` field through the `Balance` interface
        //
        adminAccount.link<&stFlowToken.Vault{FungibleToken.Balance}>(self.tokenBalancePath, target: self.tokenVaultPath)

        let admin <- create Administrator()
        adminAccount.save(<-admin, to: /storage/stFlowTokenAdmin)

        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
