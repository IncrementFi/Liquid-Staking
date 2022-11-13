import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import LiquidStakingConfig from "../../contracts/LiquidStakingConfig.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowStakingCollection from "../../contracts/standard/emulator/FlowStakingCollection.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"
import LockedTokens from "../../contracts/standard/emulator/LockedTokens.cdc"


transaction(nodeID: String, delegatorID: UInt32) {
    prepare(userAccount: AuthAccount) {
        let flowVault = userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        var delegatroInfo = FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)
        var stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
        if stFlowVaultRef == nil {
            userAccount.save(<- stFlowToken.createEmptyVault(), to: stFlowToken.tokenVaultPath)
            userAccount.unlink(stFlowToken.tokenReceiverPath)
            userAccount.unlink(stFlowToken.tokenBalancePath)
            userAccount.link<&stFlowToken.Vault{FungibleToken.Receiver}>(stFlowToken.tokenReceiverPath, target: stFlowToken.tokenVaultPath)
            userAccount.link<&stFlowToken.Vault{FungibleToken.Balance}>(stFlowToken.tokenBalancePath, target: stFlowToken.tokenVaultPath)

            stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
        }

        let stakingCollectionRef = userAccount.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath)
        // delegator in the locked account
        let linkedAccountInfoRef = userAccount.getCapability<&LockedTokens.TokenHolder{LockedTokens.LockedAccountInfo}>(LockedTokens.LockedAccountInfoPublicPath).borrow()
        if linkedAccountInfoRef != nil {
            if nodeID == linkedAccountInfoRef!.getDelegatorNodeID() && delegatorID == linkedAccountInfoRef!.getDelegatorID() {
                let tokeHolderRef = userAccount.borrow<&LockedTokens.TokenHolder>(from: LockedTokens.TokenHolderStoragePath)?? panic("TokenHolder is not saved at specified path")
                let delegatorProxy = tokeHolderRef.borrowDelegator()
                let flowVaultToStake <- FlowToken.createEmptyVault()

                if delegatroInfo.tokensCommitted > 0.0 {
                    let committedAmount = delegatroInfo.tokensCommitted
                    // cancel committed tokens
                    delegatorProxy.requestUnstaking(amount: committedAmount)
                    delegatorProxy.withdrawUnstakedTokens(amount: committedAmount)
                    flowVaultToStake.deposit(from: <- tokeHolderRef.withdraw(amount: committedAmount))
                }
                if delegatroInfo.tokensRewarded > 0.0 {
                    let rewardedAmount = delegatroInfo.tokensRewarded
                    delegatorProxy.withdrawRewardedTokens(amount: rewardedAmount)
                    flowVaultToStake.deposit(from: <- tokeHolderRef.withdraw(amount: rewardedAmount))
                }
                if delegatroInfo.tokensUnstaked > 0.0 {
                    let unstakedAmount = delegatroInfo.tokensUnstaked
                    delegatorProxy.withdrawUnstakedTokens(amount: unstakedAmount)
                    flowVaultToStake.deposit(from: <- tokeHolderRef.withdraw(amount: unstakedAmount))
                }

                if flowVaultToStake.balance >= LiquidStakingConfig.minStakingAmount {
                    let stFlowVault <- LiquidStaking.stake(flowVault: <-(flowVaultToStake as! @FlowToken.Vault))
                    stFlowVaultRef!.deposit(from: <-stFlowVault)
                } else {
                    // Deposit dust back to user account
                    flowVault.deposit(from: <-flowVaultToStake)
                }
                
                // unstake
                if delegatroInfo.tokensStaked > 0.0 {
                    let stakedAmount = delegatroInfo.tokensStaked - delegatroInfo.tokensRequestedToUnstake
                    delegatorProxy.requestUnstaking(amount: stakedAmount)
                }
                return
            }
        }
        
        // delegator in the user account
        let migratedDelegator <- stakingCollectionRef!.removeDelegator(nodeID: nodeID, delegatorID: delegatorID)!
        let flowVaultToStake <- FlowToken.createEmptyVault()

        if delegatroInfo.tokensCommitted > 0.0 {
            migratedDelegator.requestUnstaking(amount: delegatroInfo.tokensCommitted)
            let committedVault <- migratedDelegator.withdrawUnstakedTokens(amount: delegatroInfo.tokensCommitted)
            flowVaultToStake.deposit(from: <-committedVault)
        }

        if delegatroInfo.tokensRequestedToUnstake > 0.0 {
            migratedDelegator.delegateUnstakedTokens(amount: delegatroInfo.tokensRequestedToUnstake)
        }
        if delegatroInfo.tokensRewarded > 0.0 {
            let rewardedVault <-migratedDelegator.withdrawRewardedTokens(amount: delegatroInfo.tokensRewarded)
            flowVaultToStake.deposit(from: <-rewardedVault)
        }
        if delegatroInfo.tokensUnstaked > 0.0 {
            let unstakedVault <-migratedDelegator.withdrawUnstakedTokens(amount: delegatroInfo.tokensUnstaked)
            flowVaultToStake.deposit(from: <-unstakedVault)
        }

        if flowVaultToStake.balance >= LiquidStakingConfig.minStakingAmount {
            let stFlowVault <- LiquidStaking.stake(flowVault: <-(flowVaultToStake as! @FlowToken.Vault))
            stFlowVaultRef!.deposit(from: <-stFlowVault)
        } else {
            // Deposit dust back to user account
            flowVault.deposit(from: <-flowVaultToStake)
        }

        if delegatroInfo.tokensUnstaking + delegatroInfo.tokensStaked == 0.0 {
            delegatroInfo = FlowIDTableStaking.DelegatorInfo(nodeID: migratedDelegator.nodeID, delegatorID: migratedDelegator.id)
            assert(
                delegatroInfo.tokensUnstaking
                + delegatroInfo.tokensRewarded
                + delegatroInfo.tokensUnstaked
                + delegatroInfo.tokensRequestedToUnstake
                + delegatroInfo.tokensCommitted
                + delegatroInfo.tokensStaked
                == 0.0, message: "Cannot destroy delegator"
            )
            destroy migratedDelegator
        } else {
            let outVault <- LiquidStaking.migrate(delegator: <-migratedDelegator)

            stFlowVaultRef!.deposit(from: <-outVault)
        }
    }
}