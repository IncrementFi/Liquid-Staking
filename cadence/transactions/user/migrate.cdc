import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowStakingCollection from "../../contracts/standard/emulator/FlowStakingCollection.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

transaction(nodeID: String, delegatorID: UInt32) {
    prepare(userAccount: AuthAccount) {
        let flowVault = userAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        
        let stakingCollectionRef = userAccount.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath)
            ?? panic("Could not borrow ref to StakingCollection")
        let migratedDelegator <- stakingCollectionRef.removeDelegator(nodeID: nodeID, delegatorID: delegatorID)!

        var delegatroInfo = FlowIDTableStaking.DelegatorInfo(nodeID: migratedDelegator.nodeID, delegatorID: migratedDelegator.id)
        
        if delegatroInfo.tokensCommitted > 0.0 {
            migratedDelegator.requestUnstaking(amount: delegatroInfo.tokensCommitted)
            let committedVault <- migratedDelegator.withdrawUnstakedTokens(amount: delegatroInfo.tokensCommitted)
            flowVault.deposit(from: <-committedVault)
        }
        if delegatroInfo.tokensRequestedToUnstake > 0.0 {
            migratedDelegator.delegateUnstakedTokens(amount: delegatroInfo.tokensRequestedToUnstake)
        }
        if delegatroInfo.tokensRewarded > 0.0 {
            let rewardedVault <-migratedDelegator.withdrawRewardedTokens(amount: delegatroInfo.tokensRewarded)
            flowVault.deposit(from: <-rewardedVault)
        }
        if delegatroInfo.tokensUnstaked > 0.0 {
            let unstakedVault <-migratedDelegator.withdrawUnstakedTokens(amount: delegatroInfo.tokensUnstaked)
            flowVault.deposit(from: <-unstakedVault)
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

            var stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
            if stFlowVaultRef == nil {
                userAccount.save(<- stFlowToken.createEmptyVault(), to: stFlowToken.tokenVaultPath)
                userAccount.link<&stFlowToken.Vault{FungibleToken.Receiver}>(stFlowToken.tokenReceiverPath, target: stFlowToken.tokenVaultPath)
                userAccount.link<&stFlowToken.Vault{FungibleToken.Balance}>(stFlowToken.tokenBalancePath, target: stFlowToken.tokenVaultPath)

                stFlowVaultRef = userAccount.borrow<&stFlowToken.Vault>(from: stFlowToken.tokenVaultPath)
            }

            stFlowVaultRef!.deposit(from: <-outVault)
        }
    }
}