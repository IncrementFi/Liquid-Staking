import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowStakingCollection from "../../contracts/standard/emulator/FlowStakingCollection.cdc"

transaction(nodeID: String, delegatorID: UInt32) {
    prepare(userAccount: AuthAccount) {
        let stakingCollectionRef = userAccount.borrow<&FlowStakingCollection.StakingCollection>(from: FlowStakingCollection.StakingCollectionStoragePath)
            ?? panic("Could not borrow ref to StakingCollection")
        let migratedDelegator <- stakingCollectionRef.removeDelegator(nodeID: nodeID, delegatorID: delegatorID)!

        let outVault <- LiquidStaking.migrate(delegator: <-migratedDelegator)

        log("---> migrate mint stFlow".concat(outVault.balance.toString()))

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